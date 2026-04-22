// All permission keys matching backend seed data.
// Format: MODULE_CODE.RESOURCE_CODE.ACTION_CODE
class Perm {
  // ─── OPD Module ──────────────────────────────────
  static const opdPatientRead    = 'OPD.PATIENT.READ';
  static const opdPatientCreate  = 'OPD.PATIENT.CREATE';
  static const opdPatientUpdate  = 'OPD.PATIENT.UPDATE';
  static const opdPatientCancel  = 'OPD.PATIENT.CANCEL';
  static const opdPatientRefund  = 'OPD.PATIENT.REFUND';
  static const opdPatientPrint   = 'OPD.PATIENT.PRINT';

  static const opdReceiptRead    = 'OPD.RECEIPT.READ';
  static const opdReceiptCreate  = 'OPD.RECEIPT.CREATE';
  static const opdReceiptUpdate  = 'OPD.RECEIPT.UPDATE';
  static const opdReceiptCancel  = 'OPD.RECEIPT.CANCEL';
  static const opdReceiptRefund  = 'OPD.RECEIPT.REFUND';
  static const opdReceiptPrint   = 'OPD.RECEIPT.PRINT';

  static const opdShiftCreate    = 'OPD.SHIFT.CREATE';
  static const opdShiftRead      = 'OPD.SHIFT.READ';
  static const opdShiftClose     = 'OPD.SHIFT.CLOSE';

  static const opdShiftCashRead   = 'OPD.SHIFT_CASH.READ';
  static const opdShiftCashUpdate = 'OPD.SHIFT_CASH.UPDATE';
  static const opdShiftCashClose  = 'OPD.SHIFT_CASH.CLOSE';
  static const opdShiftCashPrint  = 'OPD.SHIFT_CASH.PRINT';

  static const opdServicesRead    = 'OPD.SERVICES.READ';
  static const opdServicesCreate  = 'OPD.SERVICES.CREATE';
  static const opdServicesUpdate  = 'OPD.SERVICES.UPDATE';
  static const opdServicesDelete  = 'OPD.SERVICES.DELETE';

  static const opdReportsRead    = 'OPD.REPORTS.READ';
  static const opdReportsPrint   = 'OPD.REPORTS.PRINT';

  // ─── Appointments ─────────────────────────────────
  static const apptRead    = 'APPOINTMENTS.APPOINTMENT.READ';
  static const apptCreate  = 'APPOINTMENTS.APPOINTMENT.CREATE';
  static const apptUpdate  = 'APPOINTMENTS.APPOINTMENT.UPDATE';
  static const apptDelete  = 'APPOINTMENTS.APPOINTMENT.DELETE';

  // ─── Doctors ──────────────────────────────────────
  static const doctorsRead   = 'DOCTORS.DOCTOR.READ';
  static const doctorsCreate = 'DOCTORS.DOCTOR.CREATE';
  static const doctorsUpdate = 'DOCTORS.DOCTOR.UPDATE';
  static const doctorsDelete = 'DOCTORS.DOCTOR.DELETE';

  // ─── Medical Records ──────────────────────────────
  static const mrRead   = 'MR.PATIENT.READ';
  static const mrCreate = 'MR.PATIENT.CREATE';
  static const mrUpdate = 'MR.PATIENT.UPDATE';
  static const mrDelete = 'MR.PATIENT.DELETE';

  // ─── Lab ──────────────────────────────────────────
  static const labRead   = 'LAB.TEST.READ';
  static const labCreate = 'LAB.TEST.CREATE';
  static const labUpdate = 'LAB.TEST.UPDATE';
  static const labDelete = 'LAB.TEST.DELETE';

  // ─── Radiology ────────────────────────────────────
  static const radiologyRead   = 'RADIOLOGY.TEST.READ';
  static const radiologyCreate = 'RADIOLOGY.TEST.CREATE';

  // ─── Indoor ───────────────────────────────────────
  static const indoorRead   = 'INDOOR.SERVICE.READ';
  static const indoorCreate = 'INDOOR.SERVICE.CREATE';

  // ─── Expenses ─────────────────────────────────────
  static const expenseRead   = 'EXPENSES.EXPENSE.READ';
  static const expenseCreate = 'EXPENSES.EXPENSE.CREATE';
  static const expenseUpdate = 'EXPENSES.EXPENSE.UPDATE';
  static const expenseDelete = 'EXPENSES.EXPENSE.DELETE';

  static const expenseHeadRead   = 'EXPENSES.EXPENSE_HEAD.READ';
  static const expenseHeadCreate = 'EXPENSES.EXPENSE_HEAD.CREATE';

  // ─── Emergency ────────────────────────────────────
  static const emergencyRead   = 'EMERGENCY.TREATMENT.READ';
  static const emergencyCreate = 'EMERGENCY.TREATMENT.CREATE';
  static const emergencyUpdate = 'EMERGENCY.TREATMENT.UPDATE';
  static const emergencyDelete = 'EMERGENCY.TREATMENT.DELETE';

  // ─── Consultant Payments ──────────────────────────
  static const consultantRead   = 'CONSULTANT.PAYMENT.READ';
  static const consultantCreate = 'CONSULTANT.PAYMENT.CREATE';
  static const consultantUpdate = 'CONSULTANT.PAYMENT.UPDATE';

  // ─── Setup ────────────────────────────────────────
  static const setupDiscountTypeRead   = 'SETUP.DISCOUNT_TYPE.READ';
  static const setupDiscountTypeCreate = 'SETUP.DISCOUNT_TYPE.CREATE';
  static const setupDiscountAuthRead   = 'SETUP.DISCOUNT_AUTHORITY.READ';
  static const setupDiscountAuthCreate = 'SETUP.DISCOUNT_AUTHORITY.CREATE';
  static const setupRefFromRead        = 'SETUP.REFERRED_FROM.READ';

  // ─── Company Settings ─────────────────────────────
  static const companyRead   = 'COMPANY.SETTINGS.READ';
  static const companyUpdate = 'COMPANY.SETTINGS.UPDATE';

  // ─── Access Control (Admin) ───────────────────────
  static const accessGroupsRead    = 'ACCESS.GROUPS.READ';
  static const accessGroupsCreate  = 'ACCESS.GROUPS.CREATE';
  static const accessGroupsUpdate  = 'ACCESS.GROUPS.UPDATE';
  static const accessGroupsDelete  = 'ACCESS.GROUPS.DELETE';
  static const accessPermsRead     = 'ACCESS.PERMISSIONS.READ';
  static const accessUserGroupsRead    = 'ACCESS.USER_GROUPS.READ';
  static const accessUserGroupsUpdate  = 'ACCESS.USER_GROUPS.UPDATE';

  /// Super Admin wildcard — matches everything
  static const wildcard = '*';
}
