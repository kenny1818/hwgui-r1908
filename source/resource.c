//
// HWGUI - Harbour Win32 GUI library source code:
// C level resource functions
//
// Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
// www - http://sites.uol.com.br/culikr/
//

#include "hwingui.h"
#if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
#include <prsht.h>
#endif

#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>
#include <hbinit.h>

HMODULE hModule;

HB_FUNC(HWG_GETRESOURCES)
{
  hb_retnint((LONG_PTR)hModule);
}

HB_FUNC(HWG_LOADSTRING)
{
  TCHAR buffer[2048];
  int iBuffRet = LoadString((HINSTANCE)hModule, hwg_par_UINT(2), buffer, 2048);
  HB_RETSTRLEN(buffer, iBuffRet);
}

HB_FUNC(HWG_LOADRESOURCE)
{
  void *hString;
  hModule = GetModuleHandle(HB_PARSTR(1, &hString, HWG_NULLPTR));
  hb_strfree(hString);
}

void hb_resourcemodules(void *cargo)
{
  HB_SYMBOL_UNUSED(cargo);

  hModule = GetModuleHandle(HWG_NULLPTR);
}

HB_CALL_ON_STARTUP_BEGIN(_hwgui_module_init_)
hb_vmAtInit(hb_resourcemodules, HWG_NULLPTR);
HB_CALL_ON_STARTUP_END(_hwgui_module_init_)

#if defined(HB_PRAGMA_STARTUP)
#pragma startup _hwgui_module_init_
#elif defined(HB_DATASEG_STARTUP)
#define HB_DATASEG_BODY HB_DATASEG_FUNC(_hwgui_module_init_)
#include "hbiniseg.h"
#elif defined(HB_MSC_STARTUP) // support for old [x]Harbour version
#if defined(HB_OS_WIN_64)
#pragma section(HB_MSC_START_SEGMENT, long, read)
#endif
#pragma data_seg(HB_MSC_START_SEGMENT)
static HB_$INITSYM hb_vm_auto_hwgui_module_init_ = _hwgui_module_init_;
#pragma data_seg()
#endif

HB_FUNC(HWG_FINDRESOURCE)
{
  HRSRC hHRSRC;
  int iName = hb_parni(2); // "WindowsXP.Manifest";
  int iType = hb_parni(3); // RT_MANIFEST = 24
  void *hString;

  hModule = GetModuleHandle(HB_PARSTR(1, &hString, HWG_NULLPTR));
  hb_strfree(hString);

  if (IS_INTRESOURCE(iName))
  {
    hHRSRC = FindResource((HMODULE)hModule, MAKEINTRESOURCE(iName), MAKEINTRESOURCE(iType));
    HB_RETHANDLE(hHRSRC);
  }
  else
  {
    HB_RETHANDLE(HWG_NULLPTR);
  }
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETRESOURCES, HWG_GETRESOURCES);
HB_FUNC_TRANSLATE(LOADSTRING, HWG_LOADSTRING);
HB_FUNC_TRANSLATE(LOADRESOURCE, HWG_LOADRESOURCE);
HB_FUNC_TRANSLATE(FINDRESOURCE, HWG_FINDRESOURCE);
#endif
