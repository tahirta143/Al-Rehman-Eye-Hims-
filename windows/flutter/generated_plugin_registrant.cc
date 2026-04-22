//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
#include <printing/printing_plugin.h>
#include <unified_esc_pos_printer/unified_esc_pos_printer_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
  PrintingPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PrintingPlugin"));
  UnifiedEscPosPrinterPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UnifiedEscPosPrinterPluginCApi"));
}
