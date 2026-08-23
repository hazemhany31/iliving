#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys
import json
import subprocess
import threading

PORT = 8000
DIRECTORY = os.path.dirname(os.path.abspath(__file__))
PRICES_FILE = os.path.join(DIRECTORY, "prices.json")
EOI_FILE = os.path.join(DIRECTORY, "eoi_submissions.json")
SYNC_SCRIPT = os.path.join(DIRECTORY, "sync_pipeline.py")

# Determine python executable (virtual environment preferred)
PYTHON_EXE = os.path.join(DIRECTORY, ".venv", "bin", "python")
if not os.path.exists(PYTHON_EXE):
    PYTHON_EXE = sys.executable

class LiveSyncHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Serve from the project directory by default
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Add CORS headers to all responses
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Client-Platform')
        super().end_headers()

    def do_OPTIONS(self):
        # Handle CORS preflight requests
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        # Redirect clean routes like /admin or /editor to prices_editor.html
        clean_path = self.path.split('?')[0].rstrip('/')
        if clean_path in ('/admin', '/editor'):
            self.send_response(302)
            self.send_header('Location', '/prices_editor.html')
            self.end_headers()
            return

        # Serve prices.json via api endpoint
        if clean_path == '/api/v1/units/prices.json':
            self.serve_prices_json()
            return
            
        # Serve EOI submissions via api endpoint
        if clean_path == '/api/v1/eois':
            self.serve_eois_json()
            return

        # Fallback to serving the Flutter web build if it exists and request is for root
        if clean_path == '' or clean_path == '/':
            web_index = os.path.join(DIRECTORY, "build", "web", "index.html")
            if os.path.exists(web_index):
                self.serve_file(web_index, "text/html")
                return

        # Handle other files under build/web/ if they exist, else default simple server behavior
        if clean_path.startswith('/'):
            rel_path = clean_path.lstrip('/')
            web_file = os.path.join(DIRECTORY, "build", "web", rel_path)
            if os.path.exists(web_file) and not os.path.isdir(web_file):
                # Infer content type
                content_type = self.guess_type(web_file)
                self.serve_file(web_file, content_type)
                return

        super().do_GET()

    def do_POST(self):
        clean_path = self.path.split('?')[0].rstrip('/')
        if clean_path == '/api/v1/units/prices.json':
            self.handle_save_prices()
            return
            
        if clean_path == '/api/v1/eoi/submit':
            self.handle_submit_eoi()
            return
        
        self.send_error(404, "Endpoint not found")

    def serve_prices_json(self):
        if not os.path.exists(PRICES_FILE):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"units": []}')
            return

        try:
            with open(PRICES_FILE, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(500, f"Error reading prices: {str(e)}")

    def serve_eois_json(self):
        if not os.path.exists(EOI_FILE):
            # Seed 3 VIP mock leads matching the sidebar leaderboard
            mock_leads = {
                "eois": [
                    {
                        "id": "eoi_seed_1",
                        "name": "Maximilian Von",
                        "email": "max@von-capital.com",
                        "phone": "+44 7700 900077",
                        "amount": 24000000,
                        "compound_id": "dev_3",
                        "compound_title": "Zayed Lagoons",
                        "unit_type": "Villa",
                        "payment_method": "Crypto Escrow",
                        "timestamp": "2026-07-08T15:24:00Z"
                    },
                    {
                        "id": "eoi_seed_2",
                        "name": "Seraphina Laurent",
                        "email": "seraphina@laurent-couture.fr",
                        "phone": "+33 6 5557 0192",
                        "amount": 18500000,
                        "compound_id": "dev_1",
                        "compound_title": "Sky Hills",
                        "unit_type": "Penthouse",
                        "payment_method": "Credit Card (Stripe)",
                        "timestamp": "2026-07-08T16:45:00Z"
                    },
                    {
                        "id": "eoi_seed_3",
                        "name": "Alistair Sterling",
                        "email": "sterling@iliving.com.eg",
                        "phone": "+20 100 019 7979",
                        "amount": 15200000,
                        "compound_id": "dev_2",
                        "compound_title": "Lamar Compound",
                        "unit_type": "Duplex",
                        "payment_method": "Bank Transfer",
                        "timestamp": "2026-07-08T17:10:00Z"
                    }
                ]
            }
            try:
                with open(EOI_FILE, 'w', encoding='utf-8') as f:
                    json.dump(mock_leads, f, indent=2, ensure_ascii=False)
            except Exception as e:
                print(f"[Backend] Error seeding EOI: {e}", file=sys.stderr)
        
        try:
            with open(EOI_FILE, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(500, f"Error reading EOI: {str(e)}")

    def serve_file(self, filepath, content_type):
        try:
            with open(filepath, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(500, f"Error serving file: {str(e)}")

    def handle_save_prices(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Verify valid JSON
            parsed_data = json.loads(post_data.decode('utf-8'))
            
            # Format nicely
            formatted_json = json.dumps(parsed_data, indent=2, ensure_ascii=False)
            
            # Save to prices.json
            with open(PRICES_FILE, 'w', encoding='utf-8') as f:
                f.write(formatted_json)
            
            print(f"\n[Backend] Saved updated listings to prices.json ({len(parsed_data.get('units', []))} units)")
            
            # Trigger sync pipeline in a background thread to avoid blocking client response
            threading.Thread(target=self.run_sync_pipeline).start()
            
            # Send successful response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(formatted_json.encode('utf-8'))
            
        except Exception as e:
            print(f"[Backend] Error saving prices: {e}", file=sys.stderr)
            self.send_error(400, f"Invalid request or JSON structure: {str(e)}")

    def handle_submit_eoi(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Verify valid JSON
            parsed_data = json.loads(post_data.decode('utf-8'))
            
            # Auto-populate missing fields like timestamp/id if not present
            import datetime
            if 'timestamp' not in parsed_data:
                parsed_data['timestamp'] = datetime.datetime.now().isoformat() + 'Z'
            if 'id' not in parsed_data:
                import uuid
                parsed_data['id'] = 'eoi_' + uuid.uuid4().hex[:8]
            
            # Load existing EOI submissions
            eois = []
            if os.path.exists(EOI_FILE):
                try:
                    with open(EOI_FILE, 'r', encoding='utf-8') as f:
                        existing = json.load(f)
                        eois = existing.get('eois', [])
                except Exception as e:
                    print(f"[Backend] Warning: could not parse existing EOI: {e}", file=sys.stderr)
            
            # Append new EOI
            eois.append(parsed_data)
            
            # Save back to eoi_submissions.json
            output_data = {"eois": eois}
            formatted_json = json.dumps(output_data, indent=2, ensure_ascii=False)
            
            with open(EOI_FILE, 'w', encoding='utf-8') as f:
                f.write(formatted_json)
                
            print(f"\n[Backend] Captured EOI from client '{parsed_data.get('name')}' for {parsed_data.get('amount')} EGP.")
            
            # Send successful response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "eoi": parsed_data}).encode('utf-8'))
            
        except Exception as e:
            print(f"[Backend] Error saving EOI: {e}", file=sys.stderr)
            self.send_error(400, f"Invalid request or JSON structure: {str(e)}")

    def run_sync_pipeline(self):
        print("[Backend] Triggering automatic sync_pipeline.py...")
        try:
            result = subprocess.run(
                [PYTHON_EXE, SYNC_SCRIPT],
                cwd=DIRECTORY,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                print("[Backend] ✓ sync_pipeline.py run successful.")
            else:
                print(f"[Backend] ✗ sync_pipeline.py failed (code {result.returncode}):\n{result.stderr}", file=sys.stderr)
        except subprocess.TimeoutExpired:
            print("[Backend] ✗ sync_pipeline.py timed out after 30 seconds", file=sys.stderr)
        except Exception as e:
            print(f"[Backend] ✗ Error running sync_pipeline.py: {e}", file=sys.stderr)

def main():
    # Make sure we don't bind to an address in use
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), LiveSyncHandler) as httpd:
        print("=" * 70)
        print(f"iLiving LiveSync Server started on http://localhost:{PORT}")
        print(f"Admin portal: http://localhost:{PORT}/prices_editor.html")
        print(f"Serving workspace: {DIRECTORY}")
        print("=" * 70)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")
            sys.exit(0)

if __name__ == "__main__":
    main()
