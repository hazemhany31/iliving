import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'iLiving Luxury Real Estate'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your luxury real estate portal'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @quickAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Admin Access'**
  String get quickAdminAccess;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @guestLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get guestLogin;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navPropertyOps.
  ///
  /// In en, this message translates to:
  /// **'Property Operations'**
  String get navPropertyOps;

  /// No description provided for @navElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity & Utilities'**
  String get navElectricity;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get navBookings;

  /// No description provided for @navEoi.
  ///
  /// In en, this message translates to:
  /// **'EOI Capture'**
  String get navEoi;

  /// No description provided for @navPrypco.
  ///
  /// In en, this message translates to:
  /// **'PRYPCO Hub'**
  String get navPrypco;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Document Viewer'**
  String get navDocuments;

  /// No description provided for @navYield.
  ///
  /// In en, this message translates to:
  /// **'Yield Analytics'**
  String get navYield;

  /// No description provided for @navCompoundMap.
  ///
  /// In en, this message translates to:
  /// **'Compound Map'**
  String get navCompoundMap;

  /// No description provided for @navAdminPortal.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get navAdminPortal;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get navLogout;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get dashboardGreeting;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Overview'**
  String get dashboardOverview;

  /// No description provided for @activeContracts.
  ///
  /// In en, this message translates to:
  /// **'Active Contracts'**
  String get activeContracts;

  /// No description provided for @totalInvestments.
  ///
  /// In en, this message translates to:
  /// **'Total Investments'**
  String get totalInvestments;

  /// No description provided for @upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get upcomingPayments;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivities;

  /// No description provided for @propertiesOwned.
  ///
  /// In en, this message translates to:
  /// **'Properties Owned'**
  String get propertiesOwned;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Portfolio Value'**
  String get totalValue;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyDetails;

  /// No description provided for @unitNumber.
  ///
  /// In en, this message translates to:
  /// **'Unit Number'**
  String get unitNumber;

  /// No description provided for @buildingName.
  ///
  /// In en, this message translates to:
  /// **'Building Name'**
  String get buildingName;

  /// No description provided for @compoundName.
  ///
  /// In en, this message translates to:
  /// **'Compound Name'**
  String get compoundName;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @areaSqft.
  ///
  /// In en, this message translates to:
  /// **'Area (Sq Ft)'**
  String get areaSqft;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @requestGatePass.
  ///
  /// In en, this message translates to:
  /// **'Request Gate Pass'**
  String get requestGatePass;

  /// No description provided for @maintenanceRequest.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Request'**
  String get maintenanceRequest;

  /// No description provided for @downloadContract.
  ///
  /// In en, this message translates to:
  /// **'Download Contract'**
  String get downloadContract;

  /// No description provided for @utilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity & Utility Payments'**
  String get utilityTitle;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @meterNumber.
  ///
  /// In en, this message translates to:
  /// **'Meter Number'**
  String get meterNumber;

  /// No description provided for @currentBill.
  ///
  /// In en, this message translates to:
  /// **'Current Bill Amount'**
  String get currentBill;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get creditCard;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed Successfully'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get receipt;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings & Reservations'**
  String get myBookings;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit Amount'**
  String get depositAmount;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @eoiTitle.
  ///
  /// In en, this message translates to:
  /// **'Expression of Interest (EOI)'**
  String get eoiTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @preferredProject.
  ///
  /// In en, this message translates to:
  /// **'Preferred Project'**
  String get preferredProject;

  /// No description provided for @budgetRange.
  ///
  /// In en, this message translates to:
  /// **'Budget Range'**
  String get budgetRange;

  /// No description provided for @paymentPlan.
  ///
  /// In en, this message translates to:
  /// **'Preferred Payment Plan'**
  String get paymentPlan;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get signature;

  /// No description provided for @submitEoi.
  ///
  /// In en, this message translates to:
  /// **'Submit Expression of Interest'**
  String get submitEoi;

  /// No description provided for @eoiSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your EOI has been submitted successfully!'**
  String get eoiSuccess;

  /// No description provided for @prypcoTitle.
  ///
  /// In en, this message translates to:
  /// **'PRYPCO Fractional Real Estate'**
  String get prypcoTitle;

  /// No description provided for @expectedYield.
  ///
  /// In en, this message translates to:
  /// **'Expected Annual Yield'**
  String get expectedYield;

  /// No description provided for @minimumInvestment.
  ///
  /// In en, this message translates to:
  /// **'Minimum Investment'**
  String get minimumInvestment;

  /// No description provided for @investNow.
  ///
  /// In en, this message translates to:
  /// **'Invest Now'**
  String get investNow;

  /// No description provided for @investmentCalculator.
  ///
  /// In en, this message translates to:
  /// **'Investment Calculator'**
  String get investmentCalculator;

  /// No description provided for @projectedReturns.
  ///
  /// In en, this message translates to:
  /// **'Projected Returns'**
  String get projectedReturns;

  /// No description provided for @docTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Viewer & Vault'**
  String get docTitle;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @identityDocs.
  ///
  /// In en, this message translates to:
  /// **'Identity Documents'**
  String get identityDocs;

  /// No description provided for @gatePasses.
  ///
  /// In en, this message translates to:
  /// **'Gate Passes'**
  String get gatePasses;

  /// No description provided for @yieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Yield & ROI Analytics'**
  String get yieldTitle;

  /// No description provided for @capitalAppreciation.
  ///
  /// In en, this message translates to:
  /// **'Capital Appreciation'**
  String get capitalAppreciation;

  /// No description provided for @rentalYield.
  ///
  /// In en, this message translates to:
  /// **'Rental Yield'**
  String get rentalYield;

  /// No description provided for @historicalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Historical Performance'**
  String get historicalPerformance;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive Master Plan'**
  String get mapTitle;

  /// No description provided for @availableUnits.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableUnits;

  /// No description provided for @reservedUnits.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reservedUnits;

  /// No description provided for @soldUnits.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldUnits;

  /// No description provided for @filterByPrice.
  ///
  /// In en, this message translates to:
  /// **'Filter by Price'**
  String get filterByPrice;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'iLiving Executive Admin Portal'**
  String get adminTitle;

  /// No description provided for @executiveDashboard.
  ///
  /// In en, this message translates to:
  /// **'Executive Dashboard'**
  String get executiveDashboard;

  /// No description provided for @projectsModule.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsModule;

  /// No description provided for @compoundsModule.
  ///
  /// In en, this message translates to:
  /// **'Compounds'**
  String get compoundsModule;

  /// No description provided for @buildingsModule.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get buildingsModule;

  /// No description provided for @unitInventoryModule.
  ///
  /// In en, this message translates to:
  /// **'Unit Inventory'**
  String get unitInventoryModule;

  /// No description provided for @contractsModule.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contractsModule;

  /// No description provided for @installmentsModule.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installmentsModule;

  /// No description provided for @paymentsModule.
  ///
  /// In en, this message translates to:
  /// **'Payments Ledger'**
  String get paymentsModule;

  /// No description provided for @customersModule.
  ///
  /// In en, this message translates to:
  /// **'Customer CRM'**
  String get customersModule;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @occupancyRate.
  ///
  /// In en, this message translates to:
  /// **'Occupancy Rate'**
  String get occupancyRate;

  /// No description provided for @totalUnitsCount.
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get totalUnitsCount;

  /// No description provided for @salesPerformance.
  ///
  /// In en, this message translates to:
  /// **'Sales Performance'**
  String get salesPerformance;

  /// No description provided for @revenueDistribution.
  ///
  /// In en, this message translates to:
  /// **'Revenue Distribution'**
  String get revenueDistribution;

  /// No description provided for @monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trend'**
  String get monthlyTrend;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add New Project'**
  String get addProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @addCompound.
  ///
  /// In en, this message translates to:
  /// **'Add New Compound'**
  String get addCompound;

  /// No description provided for @editCompound.
  ///
  /// In en, this message translates to:
  /// **'Edit Compound'**
  String get editCompound;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @addBuilding.
  ///
  /// In en, this message translates to:
  /// **'Add Building'**
  String get addBuilding;

  /// No description provided for @editBuilding.
  ///
  /// In en, this message translates to:
  /// **'Edit Building'**
  String get editBuilding;

  /// No description provided for @totalFloors.
  ///
  /// In en, this message translates to:
  /// **'Total Floors'**
  String get totalFloors;

  /// No description provided for @completionDate.
  ///
  /// In en, this message translates to:
  /// **'Completion Date'**
  String get completionDate;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get editUnit;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @addContract.
  ///
  /// In en, this message translates to:
  /// **'Add Contract'**
  String get addContract;

  /// No description provided for @editContract.
  ///
  /// In en, this message translates to:
  /// **'Edit Contract'**
  String get editContract;

  /// No description provided for @contractNumber.
  ///
  /// In en, this message translates to:
  /// **'Contract Number'**
  String get contractNumber;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @rentAmount.
  ///
  /// In en, this message translates to:
  /// **'Rent / Total Amount'**
  String get rentAmount;

  /// No description provided for @addInstallment.
  ///
  /// In en, this message translates to:
  /// **'Add Installment'**
  String get addInstallment;

  /// No description provided for @dueDateHeader.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateHeader;

  /// No description provided for @amountHeader.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountHeader;

  /// No description provided for @penalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get penalty;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID / Passport'**
  String get nationalId;

  /// No description provided for @unitsOwned.
  ///
  /// In en, this message translates to:
  /// **'Units Owned'**
  String get unitsOwned;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDelete;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @itemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Items per page'**
  String get itemsPerPage;

  /// No description provided for @showingResults.
  ///
  /// In en, this message translates to:
  /// **'Showing {start} to {end} of {total} results'**
  String showingResults(int start, int end, int total);

  /// No description provided for @profilePictureTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePictureTitle;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @removeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Picture'**
  String get removeProfilePicture;

  /// No description provided for @enterImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Image URL'**
  String get enterImageUrl;

  /// No description provided for @imageUrlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/photo.jpg'**
  String get imageUrlPlaceholder;

  /// No description provided for @presetAvatars.
  ///
  /// In en, this message translates to:
  /// **'Preset Luxury Avatars'**
  String get presetAvatars;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdated;

  /// No description provided for @profilePictureRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed'**
  String get profilePictureRemoved;

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid image URL. Must start with http:// or https://'**
  String get invalidImageUrl;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture'**
  String get uploadFailed;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Luxury Portfolio'**
  String get portfolioTitle;

  /// No description provided for @constructionTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Construction Progress'**
  String get constructionTitle;

  /// No description provided for @salesBrokerage.
  ///
  /// In en, this message translates to:
  /// **'iLiving Sales & Brokerage'**
  String get salesBrokerage;

  /// No description provided for @navDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get navDiscovery;

  /// No description provided for @navCrmLedger.
  ///
  /// In en, this message translates to:
  /// **'CRM & Ledger'**
  String get navCrmLedger;

  /// No description provided for @salesMode.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get salesMode;

  /// No description provided for @ownerOpsMode.
  ///
  /// In en, this message translates to:
  /// **'Owner / Ops Mode'**
  String get ownerOpsMode;

  /// No description provided for @bookingLeadConsole.
  ///
  /// In en, this message translates to:
  /// **'Booking & Lead Console'**
  String get bookingLeadConsole;

  /// No description provided for @liveLeads.
  ///
  /// In en, this message translates to:
  /// **'Live Leads'**
  String get liveLeads;

  /// No description provided for @bookingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Booking Transactions'**
  String get bookingTransactions;

  /// No description provided for @activeLeadsPipeline.
  ///
  /// In en, this message translates to:
  /// **'Active Client Leads Pipeline'**
  String get activeLeadsPipeline;

  /// No description provided for @contactNow.
  ///
  /// In en, this message translates to:
  /// **'Contact Now'**
  String get contactNow;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusProposal.
  ///
  /// In en, this message translates to:
  /// **'Proposal'**
  String get statusProposal;

  /// No description provided for @statusMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get statusMeeting;

  /// No description provided for @selectDeveloperPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Select Developer Portfolio'**
  String get selectDeveloperPortfolio;

  /// No description provided for @selectUnitSpecification.
  ///
  /// In en, this message translates to:
  /// **'Select Unit Specification'**
  String get selectUnitSpecification;

  /// No description provided for @prospectClientDossier.
  ///
  /// In en, this message translates to:
  /// **'Prospect Client Dossier'**
  String get prospectClientDossier;

  /// No description provided for @clientLegalName.
  ///
  /// In en, this message translates to:
  /// **'Client Legal Entity / Individual Name'**
  String get clientLegalName;

  /// No description provided for @clientEmail.
  ///
  /// In en, this message translates to:
  /// **'Client Secure Contact Email'**
  String get clientEmail;

  /// No description provided for @verifiedMobile.
  ///
  /// In en, this message translates to:
  /// **'Verified Mobile (Including CC)'**
  String get verifiedMobile;

  /// No description provided for @commitEoi.
  ///
  /// In en, this message translates to:
  /// **'Commit Secure EOI Capture'**
  String get commitEoi;

  /// No description provided for @prypcoHubTitle.
  ///
  /// In en, this message translates to:
  /// **'PRYPCO Investment Hub'**
  String get prypcoHubTitle;

  /// No description provided for @mortgagePreApproval.
  ///
  /// In en, this message translates to:
  /// **'Mortgage Pre-Approval'**
  String get mortgagePreApproval;

  /// No description provided for @fractionalBlocks.
  ///
  /// In en, this message translates to:
  /// **'Fractional Blocks'**
  String get fractionalBlocks;

  /// No description provided for @fractionalMicroAssets.
  ///
  /// In en, this message translates to:
  /// **'PRYPCO Fractional Micro-Assets'**
  String get fractionalMicroAssets;

  /// No description provided for @fractionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Co-own highly vetted high-yield luxury real estate starting from minor allocations.'**
  String get fractionalSubtitle;

  /// No description provided for @estRoi.
  ///
  /// In en, this message translates to:
  /// **'EST. ROI'**
  String get estRoi;

  /// No description provided for @minEntry.
  ///
  /// In en, this message translates to:
  /// **'MIN ENTRY'**
  String get minEntry;

  /// No description provided for @funded.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get funded;

  /// No description provided for @installmentReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Installment Reminder Settings'**
  String get installmentReminderSettings;

  /// No description provided for @reminderDaysBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'Reminder Days Before Due Date'**
  String get reminderDaysBeforeDue;

  /// No description provided for @addReminderDay.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder Day'**
  String get addReminderDay;

  /// No description provided for @runReminderEngine.
  ///
  /// In en, this message translates to:
  /// **'Run Reminder Engine Now'**
  String get runReminderEngine;

  /// No description provided for @reminderEngineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder engine executed successfully. Dispatched {count} push notifications.'**
  String reminderEngineSuccess(Object count);

  /// No description provided for @viewStatementPdf.
  ///
  /// In en, this message translates to:
  /// **'View Statement PDF'**
  String get viewStatementPdf;

  /// No description provided for @uploadStatementPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload Statement PDF'**
  String get uploadStatementPdf;

  /// No description provided for @latestStatementPdf.
  ///
  /// In en, this message translates to:
  /// **'Latest Statement PDF'**
  String get latestStatementPdf;

  /// No description provided for @previousStatementPdf.
  ///
  /// In en, this message translates to:
  /// **'Previous Statement PDF'**
  String get previousStatementPdf;

  /// No description provided for @noPdfAvailable.
  ///
  /// In en, this message translates to:
  /// **'No PDF Statement Available'**
  String get noPdfAvailable;

  /// No description provided for @autoRemindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable Automated Reminders'**
  String get autoRemindersEnabled;

  /// No description provided for @daysBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{days} Days Before'**
  String daysBeforeDue(Object days);

  /// No description provided for @ownerOpsModeHeader.
  ///
  /// In en, this message translates to:
  /// **'OWNER / OPS MODE'**
  String get ownerOpsModeHeader;

  /// No description provided for @realTimeSystemOperations.
  ///
  /// In en, this message translates to:
  /// **'REAL-TIME SYSTEM OPERATIONS'**
  String get realTimeSystemOperations;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOut;

  /// No description provided for @cloudSyncConnected.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync: Connected (Tap to Sync)'**
  String get cloudSyncConnected;

  /// No description provided for @cloudSyncRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync Connection Refreshed'**
  String get cloudSyncRefreshed;

  /// No description provided for @realTimeSyncActivated.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Sync Activated'**
  String get realTimeSyncActivated;

  /// No description provided for @restrictedOwnerAccess.
  ///
  /// In en, this message translates to:
  /// **'RESTRICTED OWNER ACCESS'**
  String get restrictedOwnerAccess;

  /// No description provided for @myAllocatedPortfolioAsset.
  ///
  /// In en, this message translates to:
  /// **'MY ALLOCATED PORTFOLIO ASSET'**
  String get myAllocatedPortfolioAsset;

  /// No description provided for @selectPortfolioAsset.
  ///
  /// In en, this message translates to:
  /// **'SELECT PORTFOLIO ASSET'**
  String get selectPortfolioAsset;

  /// No description provided for @projectCompoundHeader.
  ///
  /// In en, this message translates to:
  /// **'PROJECT / COMPOUND'**
  String get projectCompoundHeader;

  /// No description provided for @unitAllocationHeader.
  ///
  /// In en, this message translates to:
  /// **'UNIT ALLOCATION'**
  String get unitAllocationHeader;

  /// No description provided for @allocatedUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'ALLOCATED UNIT: {unit}'**
  String allocatedUnitLabel(String unit);

  /// No description provided for @selectedUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'SELECTED UNIT: {unit}'**
  String selectedUnitLabel(String unit);

  /// No description provided for @searchAllocatedUnits.
  ///
  /// In en, this message translates to:
  /// **'Search your allocated units...'**
  String get searchAllocatedUnits;

  /// No description provided for @quickSearchUnitPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Quick search unit (e.g. B202, B201, B203...)'**
  String get quickSearchUnitPlaceholder;

  /// No description provided for @propertyInformation.
  ///
  /// In en, this message translates to:
  /// **'PROPERTY INFORMATION'**
  String get propertyInformation;

  /// No description provided for @unitTypeConfig.
  ///
  /// In en, this message translates to:
  /// **'Unit Type / Config'**
  String get unitTypeConfig;

  /// No description provided for @unitAreaSqmSqft.
  ///
  /// In en, this message translates to:
  /// **'Unit Area (Sqm / Sqft)'**
  String get unitAreaSqmSqft;

  /// No description provided for @unitStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Status'**
  String get unitStatusLabel;

  /// No description provided for @priceValuation.
  ///
  /// In en, this message translates to:
  /// **'Price Valuation'**
  String get priceValuation;

  /// No description provided for @ownershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Ownership Status'**
  String get ownershipStatus;

  /// No description provided for @soldToUser.
  ///
  /// In en, this message translates to:
  /// **'Sold to {name}'**
  String soldToUser(String name);

  /// No description provided for @developerInventory.
  ///
  /// In en, this message translates to:
  /// **'Developer Inventory'**
  String get developerInventory;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER INFORMATION'**
  String get customerInformation;

  /// No description provided for @noCustomerAssigned.
  ///
  /// In en, this message translates to:
  /// **'No customer assigned to this unit yet.'**
  String get noCustomerAssigned;

  /// No description provided for @unassignedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Customer'**
  String get unassignedCustomer;

  /// No description provided for @clientCode.
  ///
  /// In en, this message translates to:
  /// **'Client Code'**
  String get clientCode;

  /// No description provided for @kycStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC Status'**
  String get kycStatus;

  /// No description provided for @contractNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Number'**
  String get contractNumberLabel;

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get verifiedStatus;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL OVERVIEW'**
  String get financialOverview;

  /// No description provided for @maintDeposit.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Deposit'**
  String get maintDeposit;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstandingBalance;

  /// No description provided for @installmentSchedulePayments.
  ///
  /// In en, this message translates to:
  /// **'INSTALLMENT SCHEDULE & PAYMENTS'**
  String get installmentSchedulePayments;

  /// No description provided for @totalInstCount.
  ///
  /// In en, this message translates to:
  /// **'Total Inst'**
  String get totalInstCount;

  /// No description provided for @noInstallmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No installment schedule records found in Firestore for this unit.'**
  String get noInstallmentsFound;

  /// No description provided for @maintDepositItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Deposit'**
  String get maintDepositItemTitle;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueLabel(String date);

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get statusWaiting;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'UNPAID'**
  String get statusUnpaid;

  /// No description provided for @payAndUploadProof.
  ///
  /// In en, this message translates to:
  /// **'PAY & UPLOAD PROOF'**
  String get payAndUploadProof;

  /// No description provided for @maintenanceOperations.
  ///
  /// In en, this message translates to:
  /// **'MAINTENANCE / OPERATIONS'**
  String get maintenanceOperations;

  /// No description provided for @openTicketsCount.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get openTicketsCount;

  /// No description provided for @inProgressCount.
  ///
  /// In en, this message translates to:
  /// **'In-Progress'**
  String get inProgressCount;

  /// No description provided for @noMaintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'No maintenance requests filed for this unit.'**
  String get noMaintenanceRequests;

  /// No description provided for @fileServiceRequest.
  ///
  /// In en, this message translates to:
  /// **'FILE SERVICE REQUEST'**
  String get fileServiceRequest;

  /// No description provided for @ticketUrgencyPriority.
  ///
  /// In en, this message translates to:
  /// **'TICKET URGENCY PRIORITY'**
  String get ticketUrgencyPriority;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'REQUEST {trade} SERVICE'**
  String requestService(String trade);

  /// No description provided for @filingOperationalTicket.
  ///
  /// In en, this message translates to:
  /// **'Filing operational ticket for Unit {unit} ({compound})'**
  String filingOperationalTicket(String unit, String compound);

  /// No description provided for @ticketTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket Title'**
  String get ticketTitleLabel;

  /// No description provided for @describeServiceRequirements.
  ///
  /// In en, this message translates to:
  /// **'Describe service requirements & urgency detail'**
  String get describeServiceRequirements;

  /// No description provided for @verifMin5Chars.
  ///
  /// In en, this message translates to:
  /// **'Verification requirement: minimum 5 characters details'**
  String get verifMin5Chars;

  /// No description provided for @residentAdmin.
  ///
  /// In en, this message translates to:
  /// **'RESIDENT-ADMIN'**
  String get residentAdmin;

  /// No description provided for @ticketCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service request {id} successfully registered for Unit {unit}.'**
  String ticketCreatedSuccess(String id, String unit);

  /// No description provided for @errorRegisteringTicket.
  ///
  /// In en, this message translates to:
  /// **'Error registering ticket: {error}'**
  String errorRegisteringTicket(String error);

  /// No description provided for @firestoreDataError.
  ///
  /// In en, this message translates to:
  /// **'FIRESTORE DATA ERROR'**
  String get firestoreDataError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get dismiss;

  /// No description provided for @documentsAndContracts.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS & CONTRACTS'**
  String get documentsAndContracts;

  /// No description provided for @noDocumentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No documents available for this unit.'**
  String get noDocumentsAvailable;

  /// No description provided for @downloadingFile.
  ///
  /// In en, this message translates to:
  /// **'Downloading {title}...'**
  String downloadingFile(String title);

  /// No description provided for @operationalActionsUtilities.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONAL ACTIONS & UTILITIES'**
  String get operationalActionsUtilities;

  /// No description provided for @exploreInteractiveBlueprint.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE INTERACTIVE BLUEPRINT'**
  String get exploreInteractiveBlueprint;

  /// No description provided for @exploreBlueprintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View layout showing gates, pools, clubhouses, and villa zones.'**
  String get exploreBlueprintSubtitle;

  /// No description provided for @dynamicGuestAccessQr.
  ///
  /// In en, this message translates to:
  /// **'DYNAMIC GUEST ACCESS QR'**
  String get dynamicGuestAccessQr;

  /// No description provided for @smartGateAccessFor.
  ///
  /// In en, this message translates to:
  /// **'Smart Gate Access for compound gate {compound}'**
  String smartGateAccessFor(String compound);

  /// No description provided for @courierQr.
  ///
  /// In en, this message translates to:
  /// **'Courier QR'**
  String get courierQr;

  /// No description provided for @visitorQr.
  ///
  /// In en, this message translates to:
  /// **'Visitor QR'**
  String get visitorQr;

  /// No description provided for @serviceQr.
  ///
  /// In en, this message translates to:
  /// **'Service QR'**
  String get serviceQr;

  /// No description provided for @guestPassType.
  ///
  /// In en, this message translates to:
  /// **'Guest ({type})'**
  String guestPassType(String type);

  /// No description provided for @passTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} PASS'**
  String passTypeTitle(String type);

  /// No description provided for @liveActive.
  ///
  /// In en, this message translates to:
  /// **'LIVE ACTIVE'**
  String get liveActive;

  /// No description provided for @passExpired.
  ///
  /// In en, this message translates to:
  /// **'PASS EXPIRED'**
  String get passExpired;

  /// No description provided for @passExpiredNotice.
  ///
  /// In en, this message translates to:
  /// **'Pass has expired! Please tap REGENERATE to generate a fresh QR pass.'**
  String get passExpiredNotice;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'DURATION: '**
  String get durationLabel;

  /// No description provided for @mins15.
  ///
  /// In en, this message translates to:
  /// **'15 Mins'**
  String get mins15;

  /// No description provided for @hour1.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get hour1;

  /// No description provided for @hours2.
  ///
  /// In en, this message translates to:
  /// **'2 Hours'**
  String get hours2;

  /// No description provided for @hours24.
  ///
  /// In en, this message translates to:
  /// **'24 Hours'**
  String get hours24;

  /// No description provided for @visitorNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name (Optional)'**
  String get visitorNameOptional;

  /// No description provided for @visitorMobileOptional.
  ///
  /// In en, this message translates to:
  /// **'Visitor Mobile (Optional)'**
  String get visitorMobileOptional;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WHATSAPP'**
  String get whatsapp;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'COPY CODE'**
  String get copyCode;

  /// No description provided for @regenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Regenerate QR'**
  String get regenerateQr;

  /// No description provided for @gatePassCopied.
  ///
  /// In en, this message translates to:
  /// **'Gate Pass details copied to clipboard!'**
  String get gatePassCopied;

  /// No description provided for @rfidNfcAccessKeycard.
  ///
  /// In en, this message translates to:
  /// **'RFID NFC ACCESS KEYCARD'**
  String get rfidNfcAccessKeycard;

  /// No description provided for @nfcBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {balance} EGP'**
  String nfcBalanceLabel(String balance);

  /// No description provided for @nfcSuspendedNotice.
  ///
  /// In en, this message translates to:
  /// **'NFC Keycard Balance: {balance} EGP • Status: Suspended. Contact Admin for top-up.'**
  String nfcSuspendedNotice(String balance);

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'SUSPENDED'**
  String get statusSuspended;

  /// No description provided for @viewStatus.
  ///
  /// In en, this message translates to:
  /// **'VIEW STATUS'**
  String get viewStatus;

  /// No description provided for @dispatchingWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'DISPATCHING VIA WHATSAPP API'**
  String get dispatchingWhatsapp;

  /// No description provided for @securingPassTokens.
  ///
  /// In en, this message translates to:
  /// **'Securing temporary guest gate pass tokens...'**
  String get securingPassTokens;

  /// No description provided for @rfidNfcPassReadTriggered.
  ///
  /// In en, this message translates to:
  /// **'RFID NFC PASS READ TRIGGERED'**
  String get rfidNfcPassReadTriggered;

  /// No description provided for @holdSmartTokenNearDevice.
  ///
  /// In en, this message translates to:
  /// **'Hold smart token card near device contact point...'**
  String get holdSmartTokenNearDevice;

  /// No description provided for @submitPaymentProofModalTitle.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT PAYMENT PROOF'**
  String get submitPaymentProofModalTitle;

  /// No description provided for @installmentSequenceHeader.
  ///
  /// In en, this message translates to:
  /// **'Installment #{seq} - {type}'**
  String installmentSequenceHeader(String seq, String type);

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT DUE'**
  String get amountDue;

  /// No description provided for @bankTransferInfo.
  ///
  /// In en, this message translates to:
  /// **'BANK TRANSFER INFO'**
  String get bankTransferInfo;

  /// No description provided for @uploadScreenshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Image from device:'**
  String get uploadScreenshotLabel;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @sampleReceipts.
  ///
  /// In en, this message translates to:
  /// **'Or select from Sample Receipts:'**
  String get sampleReceipts;

  /// No description provided for @proofScreenshotSelected.
  ///
  /// In en, this message translates to:
  /// **'Proof Screenshot Selected'**
  String get proofScreenshotSelected;

  /// No description provided for @transferRefNotes.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ref / Notes'**
  String get transferRefNotes;

  /// No description provided for @transferRefExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Transferred from Vodafone Cash 010...'**
  String get transferRefExample;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT FOR APPROVAL'**
  String get submitForApproval;

  /// No description provided for @paymentApprovedNotice.
  ///
  /// In en, this message translates to:
  /// **'Payment Approved Successfully!'**
  String get paymentApprovedNotice;

  /// No description provided for @paymentRejectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Proof rejected and installment returned to unpaid.'**
  String get paymentRejectedNotice;

  /// No description provided for @noScreenshotUploaded.
  ///
  /// In en, this message translates to:
  /// **'No Screenshot Uploaded'**
  String get noScreenshotUploaded;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'REJECT'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'APPROVE'**
  String get approve;

  /// No description provided for @clientCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Client / Customer:'**
  String get clientCustomerLabel;

  /// No description provided for @unitIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit ID:'**
  String get unitIdLabel;

  /// No description provided for @amountDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Due:'**
  String get amountDueLabel;

  /// No description provided for @submittedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted At:'**
  String get submittedAtLabel;

  /// No description provided for @notesRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes / Ref:'**
  String get notesRefLabel;

  /// No description provided for @proofScreenshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof Screenshot:'**
  String get proofScreenshotLabel;

  /// No description provided for @imagePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image Preview Unavailable'**
  String get imagePreviewUnavailable;

  /// No description provided for @tapRegenerateBelow.
  ///
  /// In en, this message translates to:
  /// **'Tap REGENERATE below'**
  String get tapRegenerateBelow;

  /// No description provided for @expiresInCountdown.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES IN: {hours}:{minutes}:{seconds}'**
  String expiresInCountdown(String hours, String minutes, String seconds);

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @contractValue.
  ///
  /// In en, this message translates to:
  /// **'Total Contract Value'**
  String get contractValue;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down Payment'**
  String get downPayment;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get outstanding;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
