//
// HWGUI - Harbour Win32 GUI library source code:
// HCheckComboEx class
//
// Copyright 2007 Luiz Rafale Culik Guimaraes (Luiz at xharbour.com.br)
// www - http://kresin.belgorod.su
//

#include <hbclass.ch>
#include <common.ch>
#include "hwgui.ch"

//-------------------------------------------------------------------------------------------------------------------//

#pragma begindump

#include "hwingui.h"

HB_FUNC(HWG_COPYDATA)
{
  LPARAM lParam = (LPARAM)hb_parnl(1);
  void *hText;
  LPCTSTR m_strText = HB_PARSTR(2, &hText, HWG_NULLPTR);
  WPARAM wParam = hwg_par_WPARAM(3);
  lstrcpyn((LPTSTR)lParam, m_strText, (INT)wParam);
  hb_strfree(hText);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(COPYDATA, HWG_COPYDATA);
#endif

#pragma enddump

//-------------------------------------------------------------------------------------------------------------------//

CLASS HCheckComboBox INHERIT HComboBox

   CLASS VAR winclass INIT "COMBOBOX"
   DATA m_bTextUpdated INIT .F.

   DATA m_bItemHeightSet INIT .F.
   DATA m_hListBox INIT 0
   DATA aCheck
   DATA nWidthCheck INIT 0
   DATA m_strText INIT ""
   METHOD onGetText(wParam, lParam)
   METHOD OnGetTextLength(wParam, lParam)

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
   aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, ;
   tcolor, bcolor, bValid, acheck, nDisplay, nhItem, ncWidth)
   METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, ctooltip, bGFocus, acheck)
   METHOD Init()
   METHOD Requery()
   METHOD Refresh()
   METHOD Paint(lpDis)
   METHOD SetCheck(nIndex, bFlag)
   METHOD RecalcText()

   METHOD GetCheck(nIndex)

   METHOD SelectAll(bCheck)
   METHOD MeasureItem(l)

   METHOD onEvent(msg, wParam, lParam)
   METHOD GetAllCheck()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
               bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, ;
               bValid, acheck, nDisplay, nhItem, ncWidth)

   ::acheck := IIf(acheck == NIL, {}, acheck)
   IF hb_IsNumeric(nStyle)
      nStyle := hwg_multibitor(nStyle, CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS)
   ELSE
      nStyle := hwg_multibitor(CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS)
   ENDIF

   bPaint := {|o, p|o:paint(p)}

   ::Super:New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
                bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid,, nDisplay, nhItem, ncWidth)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, ctooltip, bGFocus, acheck)

   ::Super:Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                     bChange, ctooltip, bGFocus)
   ::lResource := .T.
   ::acheck := acheck

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD HCheckComboBox:onEvent(msg, wParam, lParam)

   LOCAL nIndex
   LOCAL rcItem
   LOCAL rcClient
   LOCAL pt
   LOCAL nItemHeight
   LOCAL nTopIndex

   IF msg == WM_RBUTTONDOWN
   ELSEIF msg == LB_GETCURSEL
      RETURN -1
   ELSEIF msg == LB_GETCURSEL
      RETURN -1

   ELSEIF msg == WM_MEASUREITEM
      ::MeasureItem(lParam)
      RETURN 0
   ELSEIF msg == WM_GETTEXT
      RETURN ::OnGetText(wParam, lParam)

   ELSEIF msg == WM_GETTEXTLENGTH

      RETURN ::OnGetTextLength(wParam, lParam)

   ELSEIF msg == WM_CHAR
      IF (wParam == VK_SPACE)

         nIndex := hwg_SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
         rcItem := hwg_ComboGetItemRect(::handle, nIndex - 1)
         hwg_InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
         ::SetCheck(nIndex, !::GetCheck(nIndex))
         hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKELONG(::id, CBN_SELCHANGE), ::handle)
      ENDIF
      IF (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal)
         IF wParam == VK_TAB
            hwg_GetSkip(::oParent, ::handle,, IIf(hwg_IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wParam == VK_RETURN
            hwg_GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg == WM_KEYDOWN
      hwg_ProcKeyList(Self, wParam)

   ELSEIF msg == WM_LBUTTONDOWN

      rcClient := hwg_GetClientRect(::handle)

      pt := {,}
      pt[1] := hwg_LOWORD(lParam)
      pt[2] := hwg_HIWORD(lParam)

      IF (hwg_PtInRect(rcClient, pt))

         nItemHeight := hwg_SendMessage(::handle, LB_GETITEMHEIGHT, 0, 0)
         nTopIndex := hwg_SendMessage(::handle, LB_GETTOPINDEX, 0, 0)

         // Compute which index to check/uncheck
         nIndex := (nTopIndex + pt[2] / nItemHeight) + 1
         rcItem := hwg_ComboGetItemRect(::handle, nIndex - 1)

         //IF (hwg_PtInRect(rcItem, pt))
         IF pt[1] < ::nWidthCheck
            // Invalidate this window
            hwg_InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
            nIndex := hwg_SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
            ::SetCheck(nIndex, !::GetCheck(nIndex))

            // Notify that selection has changed

            hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKELONG(::id, CBN_SELCHANGE), ::handle)

         ENDIF
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      RETURN -1    //0
   ENDIF

RETURN -1
#else
METHOD HCheckComboBox:onEvent(msg, wParam, lParam)

   LOCAL nIndex
   LOCAL rcItem
   LOCAL rcClient
   LOCAL pt
   LOCAL nItemHeight
   LOCAL nTopIndex

   SWITCH msg

   CASE WM_RBUTTONDOWN
      EXIT

   CASE LB_GETCURSEL
      RETURN -1

   CASE WM_MEASUREITEM
      ::MeasureItem(lParam)
      RETURN 0

   CASE WM_GETTEXT
      RETURN ::OnGetText(wParam, lParam)

   CASE WM_GETTEXTLENGTH
      RETURN ::OnGetTextLength(wParam, lParam)

   CASE WM_CHAR
      IF wParam == VK_SPACE
         nIndex := hwg_SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
         rcItem := hwg_ComboGetItemRect(::handle, nIndex - 1)
         hwg_InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
         ::SetCheck(nIndex, !::GetCheck(nIndex))
         hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKELONG(::id, CBN_SELCHANGE), ::handle)
      ENDIF
      IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
         IF wParam == VK_TAB
            hwg_GetSkip(::oParent, ::handle, , IIf(hwg_IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wParam == VK_RETURN
            hwg_GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
      RETURN 0

   CASE WM_KEYDOWN
      hwg_ProcKeyList(Self, wParam)
      EXIT

   CASE WM_LBUTTONDOWN
      rcClient := hwg_GetClientRect(::handle)
      pt := {,}
      pt[1] := hwg_LOWORD(lParam)
      pt[2] := hwg_HIWORD(lParam)
      IF hwg_PtInRect(rcClient, pt)
         nItemHeight := hwg_SendMessage(::handle, LB_GETITEMHEIGHT, 0, 0)
         nTopIndex := hwg_SendMessage(::handle, LB_GETTOPINDEX, 0, 0)
         // Compute which index to check/uncheck
         nIndex := (nTopIndex + pt[2] / nItemHeight) + 1
         rcItem := hwg_ComboGetItemRect(::handle, nIndex - 1)
         //IF hwg_PtInRect(rcItem, pt)
         IF pt[1] < ::nWidthCheck
            // Invalidate this window
            hwg_InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
            nIndex := hwg_SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
            ::SetCheck(nIndex, !::GetCheck(nIndex))
            // Notify that selection has changed
            hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKELONG(::id, CBN_SELCHANGE), ::handle)
         ENDIF
      ENDIF
      EXIT

   CASE WM_LBUTTONUP
      RETURN -1 //0

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:Init()

   LOCAL i

   //::nHolder := 1
   //hwg_SetWindowObject(::handle, Self)  // because hcombobox is handling
   //HWG_INITCOMBOPROC(::handle)
   IF !::lInit
      ::Super:Init()
      IF Len(::acheck) > 0
         FOR i := 1 TO Len(::acheck)
            ::Setcheck(::acheck[i], .T.)
         NEXT
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:Requery()

   LOCAL i

   ::super:Requery()
   IF Len(::acheck) > 0
      FOR i := 1 TO Len(::acheck)
         ::Setcheck(::acheck[i], .T.)
      NEXT
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:Refresh()

   ::Super:refresh()

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:SetCheck(nIndex, bFlag)

   LOCAL nResult := hwg_ComboBoxSetItemData(::handle, nIndex - 1, bFlag)

   IF (nResult < 0)
      RETURN nResult
   ENDIF

   ::m_bTextUpdated := FALSE

   // Redraw the window
   hwg_InvalidateRect(::handle, 0)

RETURN nResult

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:GetCheck(nIndex)

   LOCAL l := hwg_ComboBoxGetItemData(::handle, nIndex - 1)

RETURN IIf(l == 1, .T., .F.)

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:SelectAll(bCheck)

   LOCAL nCount
   LOCAL i

   DEFAULT bCheck TO .T.

   nCount := hwg_SendMessage(::handle, CB_GETCOUNT, 0, 0)

   FOR i := 1 TO nCount
      ::SetCheck(i, bCheck)
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:RecalcText()

   LOCAL strtext
   LOCAL ncount
   LOCAL strSeparator
   LOCAL i
   LOCAL stritem

   IF (!::m_bTextUpdated)

      // Get the list count
      ncount := hwg_SendMessage(::handle, CB_GETCOUNT, 0, 0)

      // Get the list separator

      strSeparator := hwg_GetLocaleInfo()

      // If none found, the the ''
      IF Len(strSeparator) == 0
         strSeparator := ""
      ENDIF

      strSeparator := RTrim(strSeparator)

      strSeparator += " "

      FOR i := 1 TO ncount

         IF (hwg_ComboBoxGetItemData(::handle, i)) == 1

            hwg_ComboBoxGetLBText(::handle, i, @stritem)

            IF !Empty(strtext)
               strtext += strSeparator
            ENDIF

            strtext += stritem
         ENDIF
      NEXT

      // Set the text
      ::m_strText := strtext

      ::m_bTextUpdated := TRUE
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:Paint(lpDis)

   LOCAL drawInfo := hwg_GetDrawItemInfo(lpDis)
   LOCAL dc := drawInfo[3]
   LOCAL rcBitmap := {drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]}
   LOCAL rcText := {drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]}
   LOCAL strtext := ""
   LOCAL ncheck
   LOCAL metrics
   LOCAL nstate

   IF (drawInfo[1] < 0)

      ::RecalcText()

      strtext := ::m_strText

      ncheck := 0

   ELSE
      hwg_ComboBoxGetLBText(::handle, drawInfo[1], @strtext)

      ncheck := 1 + (hwg_ComboBoxGetItemData(::handle, drawInfo[1]))

      metrics := hwg_GetTextMetric(dc)

      rcBitmap[1] := 0
      rcBitmap[3] := rcBitmap[1] + metrics[1] + metrics[4] + 6
      rcBitmap[2] += 1
      rcBitmap[4] -= 1

      rcText[1] := rcBitmap[3]
      ::nWidthCheck := rcBitmap[3]
   ENDIF

   IF (ncheck > 0)
      hwg_SetBkColor(dc, hwg_GetSysColor(COLOR_WINDOW))
      hwg_SetTextColor(dc, hwg_GetSysColor(COLOR_WINDOWTEXT))

      nstate := DFCS_BUTTONCHECK

      IF (ncheck > 1)
         nstate := hwg_bitor(nstate, DFCS_CHECKED)
      ENDIF

      // Draw the checkmark using hwg_DrawFrameControl
      hwg_DrawFrameControl(dc, rcBitmap, DFC_BUTTON, nstate)
   ENDIF

   IF (hwg_Bitand(drawInfo[9], ODS_SELECTED) != 0)
      hwg_SetBkColor(dc, hwg_GetSysColor(COLOR_HIGHLIGHT))
      hwg_SetTextColor(dc, hwg_GetSysColor(COLOR_HIGHLIGHTTEXT))

   ELSE
      hwg_SetBkColor(dc, hwg_GetSysColor(COLOR_WINDOW))
      hwg_SetTextColor(dc, hwg_GetSysColor(COLOR_WINDOWTEXT))
   ENDIF

   // Erase and draw
   IF Empty(strtext)
      strtext := ""
   ENDIF

   hwg_ExtTextOut(dc, 0, 0, rcText[1], rcText[2], rcText[3], rcText[4])

   hwg_DrawText(dc, " " + strtext, rcText[1], rcText[2], rcText[3], rcText[4], DT_SINGLELINE + DT_VCENTER + DT_END_ELLIPSIS)

   IF ((hwg_Bitand(drawInfo[9], ODS_FOCUS + ODS_SELECTED)) == (ODS_FOCUS + ODS_SELECTED))
      hwg_DrawFocusRect(dc, rcText)
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:MeasureItem(l)

   LOCAL dc := HCLIENTDC():new(::handle)
   LOCAL lpMeasureItemStruct := hwg_GetMeasureItemInfo(l)
   LOCAL metrics
   LOCAL pFont

   //pFont := dc:SelectObject(IIf(hb_IsObject(::oFont), ::oFont:handle, ::oParent:oFont:handle))
   pFont := dc:SelectObject(IIf(hb_IsObject(::oFont), ::oFont:handle, ;
      IIf(hb_IsObject(::oParent:oFont), ::oParent:oFont:handle,)))

   IF !Empty(pFont)

      metrics := dc:GetTextMetric()

      lpMeasureItemStruct[5] := metrics[1] + metrics[4]

      lpMeasureItemStruct[5] += 2

      IF (!::m_bItemHeightSet)
         ::m_bItemHeightSet := .T.
         hwg_SendMessage(::handle, CB_SETITEMHEIGHT, - 1, hwg_MAKELONG(lpMeasureItemStruct[5], 0))
      ENDIF

      dc:SelectObject(pFont)
      dc:End()
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:OnGetText(wParam, lParam)

   ::RecalcText()

   IF (lParam == 0)
      RETURN 0
   ENDIF

   // Copy the 'fake' window text
   hwg_CopyData(lParam, ::m_strText, wParam)

RETURN IIf(Empty(::m_strText), 0, Len(::m_strText))

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:OnGetTextLength(WPARAM, LPARAM)

   HB_SYMBOL_UNUSED(WPARAM)
   HB_SYMBOL_UNUSED(LPARAM)

   ::RecalcText()

RETURN IIf(Empty(::m_strText), 0, Len(::m_strText))

//-------------------------------------------------------------------------------------------------------------------//

METHOD HCheckComboBox:GetAllCheck()

   LOCAL aCheck := {}
   LOCAL n

   FOR n := 1 TO Len(::aItems)
      AAdd(aCheck, ::GetCheck(n))
   NEXT

RETURN aCheck

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION hwg_multibitor(...)

   LOCAL aArgumentList := HB_AParams()
   LOCAL nItem
   LOCAL result := 0

   FOR EACH nItem IN aArgumentList
      IF !hb_IsNumeric(nItem)
         hwg_MsgInfo("hwg_multibitor parameter not numeric set to zero", "Possible error")
         nItem := 0
      ENDIF
      result := hwg_bitor(result, nItem)
   NEXT

RETURN result

//-------------------------------------------------------------------------------------------------------------------//
