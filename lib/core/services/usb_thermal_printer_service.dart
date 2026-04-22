import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

class UsbThermalPrinterService {
  final PrinterManager _manager = PrinterManager();

  Future<List<PrinterDevice>> scanUsbPrinters({Duration timeout = const Duration(seconds: 4)}) async {
    return _manager.scanPrinters(
      timeout: timeout,
      types: {PrinterConnectionType.usb},
    );
  }

  Future<bool> printReceipt({
    required PrinterDevice printer,
    required Ticket ticket,
  }) async {
    try {
      await _manager.connect(printer);
      await _manager.printTicket(ticket);
      await _manager.disconnect();
      return true;
    } on PrinterException {
      try {
        await _manager.disconnect();
      } catch (_) {}
      return false;
    }
  }
}

