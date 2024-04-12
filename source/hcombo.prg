/*
 * $Id: hcombo.prg 1906 2012-09-25 22:23:08Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckComboEx class
 *
 * Copyright 2007 Luiz Rafale Culik Guimaraes (Luiz at xharbour.com.br)
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

#pragma begindump

#include "hwingui.h"

HB_FUNC(COPYDATA)
{
  LPARAM lParam = (LPARAM)hb_parnl(1);
  void *hText;
  LPCTSTR m_strText = HB_PARSTR(2, &hText, NULL);
  WPARAM wParam = hwg_par_WPARAM(3);
  lstrcpyn((LPTSTR)lParam, m_strText, (INT)wParam);
  hb_strfree(hText);
}

#pragma enddump

//-------------------------------------------------------------------------------------------------------------------//

CLASS HComboBox INHERIT HControl

   CLASS VAR winclass INIT "COMBOBOX"

   DATA aItems
   DATA aItemsBound
   DATA bSetGet
   DATA value INIT 1
   DATA valueBound INIT 1
   DATA cDisplayValue HIDDEN
   DATA columnBound INIT 1 HIDDEN
   DATA xrowsource INIT {,} HIDDEN

   DATA bChangeSel
   DATA bChangeInt
   DATA bValid
   DATA bSelect

   DATA lText INIT .F.
   DATA lEdit INIT .F.
   DATA SelLeght INIT 0
   DATA SelStart INIT 0
   DATA SelText INIT ""
   DATA nDisplay
   DATA nhItem
   DATA ncWidth
   DATA nHeightBox
   DATA lResource INIT .F.
   DATA ldropshow INIT .F.
   DATA nMaxLength     INIT Nil

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, bInit, bSize, ;
      bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bLFocus, bIChange, nDisplay, nhItem, ncWidth, ;
      nMaxLength)
   METHOD Activate()
   METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, bGFocus, ;
      bLFocus, bIChange, nDisplay, nMaxLength, ledit, ltext)
   METHOD INIT()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Requery()
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD SetValue(xItem)
   METHOD GetValue()
   METHOD AddItem( cItem, cItemBound, nPos )
   METHOD DeleteItem( xIndex )
   METHOD Valid()
   METHOD When()
   METHOD onSelect()
   METHOD InteractiveChange()
   METHOD onChange(lForce)
   METHOD Populate() HIDDEN
   METHOD GetValueBound(xItem)
   METHOD RowSource(xSource) SETGET
   METHOD DisplayValue(cValue) SETGET
   METHOD onDropDown() INLINE ::ldropshow := .T.
   METHOD SetCueBanner( cText, lShowFoco )
   METHOD MaxLength( nMaxLength ) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, bInit, bSize, bPaint, ;
   bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bLFocus, bIChange, nDisplay, nhItem, ncWidth, nMaxLength) CLASS HComboBox

   IF !Empty( nDisplay ) .AND. nDisplay > 0
      nStyle := Hwg_BitOr( nStyle, CBS_NOINTEGRALHEIGHT  + WS_VSCROLL )
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
      nDisplay := 6
   ENDIF
   nHeight := IIF( EMPTY( nHeight ), 24, nHeight )
   ::nHeightBox := Int( nHeight * 0.75 )                    //   Meets A 22'S EDITBOX
   nHeight := nHeight + ( Iif( Empty( nhItem ), 16.250, ( nhItem += 0.10 ) ) * nDisplay )

   IF lEdit == Nil
      lEdit := .F.
   ENDIF

   nStyle := Hwg_BitOr( Iif( nStyle == Nil, 0, nStyle ), Iif( lEdit, CBS_DROPDOWN, CBS_DROPDOWNLIST ) + WS_TABSTOP )
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, ;
      bcolor)

   IF lText == Nil
      lText := .F.
   ENDIF

   ::nDisplay := nDisplay
   ::nhItem := nhItem
   ::ncWidth := ncWidth

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .T.
      IF nMaxLength != Nil
         ::MaxLength := nMaxLength
      ENDIF
   ENDIF

   IF ::lText
      ::value := Iif( vari == Nil .OR. !hb_IsChar(vari), "", vari )
   ELSE
      ::value := Iif( vari == Nil .OR. !hb_IsNumeric(vari), 1, vari )
   ENDIF

   aItems := IIF( aItems = Nil, {}, aClone(aItems) )
   ::RowSource(aItems)
   ::aItemsBound := {}
   ::bSetGet := bSetGet

   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus

   IF bSetGet != Nil
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus" )
      ENDIF
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      ::oParent:AddEvent( CBN_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .F., "onLostFocus" )
      //::oParent:AddEvent( CBN_KILLFOCUS, Self, {|o, id|__Valid(o:FindControl(id))}, .F., "onLostFocus" )
      //---------------------------------------------------------------------------
   ELSE
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus" )
         //::oParent:AddEvent( CBN_SETFOCUS, Self, {|o, id|__When(o:FindControl(id))},, "onGotGocus" )
      ENDIF
      ::oParent:AddEvent( CBN_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .F., "onLostFocus" )
      //::oParent:AddEvent( CBN_KILLFOCUS, Self, {|o, id|__Valid(o:FindControl(id))},, "onLostFocus" )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|::onChange(o:FindControl(id))},, "onChange" )
   ENDIF

   IF bIChange != Nil .AND. ::lEdit
      ::bchangeInt := bIChange
      //::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|__InteractiveChange(o:FindControl(id))}, , "interactiveChange")
      ::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|::InteractiveChange(o:FindControl(id))}, , "interactiveChange")
   ENDIF
   ::oParent:AddEvent(CBN_SELENDOK, Self, {|o, id|::onSelect(o:FindControl(id))},,"onSelect")
   ::oParent:AddEvent(CBN_DROPDOWN, Self, {|o, id|::onDropDown(o:FindControl(id))},,"ondropdown")
   ::oParent:AddEvent(CBN_CLOSEUP, Self, {||::ldropshow := .F.}, ,)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HComboBox

   IF !Empty( ::oParent:handle )
      ::handle := CreateCombo(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
      ::nHeight := INT( ::nHeightBox / 0.75 )
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, bGFocus, ;
   bLFocus, bIChange, nDisplay, nMaxLength,ledit, ltext) CLASS HComboBox

   HB_SYMBOL_UNUSED(bLFocus)
   //HB_SYMBOL_UNUSED(bIChange)
   IF lEdit == Nil
      lEdit := .F.
   ENDIF
   IF lText == Nil
      lText := .F.
   ENDIF

   ::lEdit := lEdit
   ::lText := lText

   //::nHeightBox := INT( 22 * 0.75 ) //   Meets A 22'S EDITBOX
   IF !Empty( nDisplay ) .AND. nDisplay > 0
      ::Style := Hwg_BitOr( ::Style, CBS_NOINTEGRALHEIGHT )                     //+ WS_VSCROLL )
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
      nDisplay := 6
   ENDIF
   //::nHeight := ( ::nHeight + 16.250 ) *  nDisplay
   ::lResource := .T.
   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip )

   ::nDisplay := nDisplay

   IF ::lText
      ::value := Iif( vari == Nil .OR. !hb_IsChar(vari), "", vari )
   ELSE
      ::value := Iif( vari == Nil .OR. !hb_IsNumeric(vari), 1, vari )
   ENDIF
   IF nMaxLength != Nil
       ::MaxLength := nMaxLength
   ENDIF

   aItems := IIF( aItems = Nil, {}, aClone(aItems) )
   ::RowSource(aItems)
   ::aItemsBound := {}
   ::bSetGet := bSetGet

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus" )
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bSetGet != NIL
         ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|::Valid(o:FindControl(id))},, "onChange" )
      // ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|__Valid(o:FindControl(id))},, "onChange" )
      ELSEIF ::bChangeSel != NIL
         ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|::Valid(o:FindControl(id))},, "onChange" )
       //  ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|__Valid(o:FindControl(id))},, "onChange" )
      ENDIF
   ELSEIF bChange != Nil .AND. ::lEdit
      ::bChangeSel := bChange
      ::oParent:AddEvent( CBN_SELCHANGE, Self, {|o, id|::onChange(o:FindControl(id))},, "onChange" )
    //::oParent:AddEvent( CBN_SELCHANGE, Self, bChange,, "onChange" )
   ENDIF

   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus" )
   ENDIF
   IF bIChange != Nil .AND. ::lEdit
      ::bchangeInt := bIChange
      //::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|__InteractiveChange(o:FindControl(id))}, , "interactiveChange")
      ::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|::InteractiveChange(o:FindControl(id))}, , "interactiveChange")
   ENDIF

   ::oParent:AddEvent(CBN_SELENDOK, Self, {|o, id|::onSelect(o:FindControl(id))}, , "onSelect")
   //::Refresh() // By Luiz Henrique dos Santos
   ::oParent:AddEvent(CBN_DROPDOWN, Self, {|o, id|::onDropDown(o:FindControl(id))}, , "ondropdown")
   ::oParent:AddEvent(CBN_CLOSEUP, Self, {||::ldropshow := .F.}, ,)

   //::Requery()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS HComboBox

   LOCAL LongComboWidth
   LOCAL NewLongComboWidth
   LOCAL avgWidth
   LOCAL nHeightBox

   IF !::lInit
      ::nHolder := 1
      SetWindowObject(::handle, Self)
      HWG_INITCOMBOPROC(::handle)
      IF ::aItems != Nil .AND. !Empty( ::aItems )
         /*
         IF ::value == Nil
            IF ::lText
               ::value := ::aItems[1]
            ELSE
               ::value := 1
            ENDIF
         ENDIF
         SendMessage(::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[i] )
            numofchars := SendMessage(::handle, CB_GETLBTEXTLEN, i - 1, 0)
            IF numofchars > LongComboWidth
               LongComboWidth := numofchars
            ENDIF
         NEXT
         */
         ::RowSource(::aItems)
         LongComboWidth := ::Populate()
         //
         IF ::lText
            IF ::lEdit
               SetDlgItemText( getmodalhandle(), ::id, ::value )
               SendMessage(::handle, CB_SELECTSTRING, -1, ::value)
               SendMessage(::handle, CB_SETEDITSEL, -1, 0)
            ELSE
               #ifdef __XHARBOUR__
               ComboSetString( ::handle, AScan( ::aItems, ::value, , , .T.  ) )
               #else
               ComboSetString( ::handle, hb_AScan( ::aItems, ::value, , , .T.  ) )
               #endif
            ENDIF
            //SendMessage(::handle, CB_SELECTSTRING, 0, ::value)
            SetWindowText( ::handle, ::value )
         ELSE
            ComboSetString( ::handle, ::value )
         ENDIF
         avgwidth := GetFontDialogUnits( ::oParent:handle ) + 0.75   //,::oParent:oFont:handle)
         NewLongComboWidth := ( LongComboWidth - 2 ) * avgwidth
         SendMessage(::handle, CB_SETDROPPEDWIDTH, NewLongComboWidth + 50, 0)
      ENDIF
      ::Super:Init()
      IF !::lResource
         // HEIGHT Items
         IF !Empty( ::nhItem )
            sendmessage(::handle, CB_SETITEMHEIGHT, 0, ::nhItem + 0.10)
         ELSE
            ::nhItem := sendmessage(::handle, CB_GETITEMHEIGHT, 0, 0) + 0.10
         ENDIF
         nHeightBox := sendmessage(::handle, CB_GETITEMHEIGHT, -1, 0) //+ 0.750
         //  WIDTH  Items
         IF !Empty( ::ncWidth )
            sendmessage(::handle, CB_SETDROPPEDWIDTH, ::ncWidth, 0)
         ENDIF
         ::nHeight := Int( nHeightBox / 0.75 + ( ::nhItem * ::nDisplay ) ) + 3
      ENDIF
   ENDIF
   IF !::lResource
      MoveWindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      // HEIGHT COMBOBOX
      SendMessage(::handle, CB_SETITEMHEIGHT, -1, ::nHeightBox)
   ENDIF
   ::Refresh()
   IF ::lEdit
      SendMessage(::handle, CB_SETEDITSEL, -1, 0)
      SendMessage(::handle, WM_SETREDRAW, 1, 0)
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference
METHOD onEvent( msg, wParam, lParam ) CLASS HComboBox

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_MOUSEWHEEL .AND. ::oParent:nScrollBars != -1 .AND. ::oParent:bScroll = Nil
      ::super:ScrollHV( ::oParent, msg, wParam, lParam )
      RETURN 0
   ELSEIF msg = CB_SHOWDROPDOWN
      ::ldropshow := IIF( wParam = 1, .T., ::ldropshow )
   ENDIF

   IF ::bSetGet != Nil .OR. ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
      IF msg == WM_CHAR .AND. ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
          !::GetParentForm( Self ) :lModal )
         IF wParam = VK_TAB
            GetSkip(::oParent, ::handle,, Iif( IsCtrlShift( .F., .T. ), - 1, 1 ))
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. ;
            !ProcOkCancel( Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE ) .AND.;
                       ( ::GetParentForm():Type < WND_DLG_RESOURCE.OR.;
                   !::GetParentForm():lModal )
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ELSEIF msg == WM_GETDLGCODE
         IF wParam = VK_RETURN
            RETURN DLGC_WANTMESSAGE
         ELSEIF wParam = VK_ESCAPE  .AND. ;
                  ( oCtrl := ::GetParentForm:FindControl( IDCANCEL ) ) != Nil .AND. !oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ENDIF
           RETURN  DLGC_WANTCHARS + DLGC_WANTARROWS

      ELSEIF msg = WM_KEYDOWN
         //ProcKeyList( Self, wParam )
         IF wparam =  VK_RIGHT .OR. wParam == VK_RETURN //.AND. !::lEdit
             GetSkip(::oParent, ::handle, , 1)
             RETURN 0
         ELSEIF wparam =  VK_LEFT //.AND. !::lEdit
               GetSkip(::oParent, ::handle, , -1)
               RETURN 0
         ELSEIF wParam = VK_ESCAPE .AND.  ::GetParentForm( Self ):Type < WND_DLG_RESOURCE //.OR.;
            RETURN 0
         ENDIF

      ELSEIF msg = WM_KEYUP
         ProcKeyList( Self, wParam )        //working in MDICHILD AND DIALOG
      ELSEIF msg =  WM_COMMAND  .AND. ::lEdit  .AND. !::ldropshow
         IF GETKEYSTATE(VK_DOWN) + GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0 .AND. HiWord(wParam) = 1
            RETURN 0
        ENDIF
      ELSEIF msg = CB_GETDROPPEDSTATE  .AND. !::ldropshow
           IF GETKEYSTATE(VK_RETURN) < 0
            ::GetValue()
          ENDIF
         IF (GETKEYSTATE(VK_RETURN) < 0 .OR. GETKEYSTATE(VK_ESCAPE) < 0) .AND. ;
            (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
            !::GetParentForm(Self):lModal)
            ProcOkCancel( Self, IIF( GETKEYSTATE(VK_RETURN) < 0, VK_RETURN, VK_ESCAPE ) )
         ENDIF
           IF GETKEYSTATE(VK_TAB) + GETKEYSTATE(VK_DOWN) < 0 .AND. GetKeyState(VK_SHIFT) > 0
            IF ::oParent:oParent = Nil
             //  GetSkip(::oParent, GetAncestor( ::handle, GA_PARENT ), , 1)
            ENDIF
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
           ELSEIF GETKEYSTATE(VK_UP) < 0 .AND.  GetKeyState(VK_SHIFT) > 0
            IF ::oParent:oParent = Nil
             //  GetSkip(::oParent, GetAncestor( ::handle, GA_PARENT ), , 1)
            ENDIF
            GetSkip(::oParent, ::handle, , -1)
            RETURN 0
         ENDIF
          IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE.OR. !::GetParentForm( Self ):lModal )
             RETURN 1
          ENDIF
      ENDIF
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HComboBox

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF
   
   // TODO: unificar switch's

   SWITCH msg

   CASE WM_MOUSEWHEEL
      IF ::oParent:nScrollBars != -1 .AND. ::oParent:bScroll == NIL
         ::super:ScrollHV(::oParent, msg, wParam, lParam)
         RETURN 0
      ENDIF
      EXIT

   CASE CB_SHOWDROPDOWN
      ::ldropshow := IIf(wParam == 1, .T., ::ldropshow)

   ENDSWITCH

   IF hb_IsBlock(::bSetGet) .OR. ::GetParentForm(Self):Type < WND_DLG_RESOURCE

      SWITCH msg

      CASE WM_CHAR
         IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
            IF wParam == VK_TAB
               GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ELSEIF wParam == VK_RETURN .AND. ;
               !ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE) .AND. ;
               (::GetParentForm():Type < WND_DLG_RESOURCE .OR. !::GetParentForm():lModal)
               GetSkip(::oParent, ::handle, , 1)
               RETURN 0
            ENDIF
         ENDIF
         EXIT

      CASE WM_GETDLGCODE
         IF wParam == VK_RETURN
            RETURN DLGC_WANTMESSAGE
         ELSEIF wParam == VK_ESCAPE .AND. ;
            (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ENDIF
         RETURN DLGC_WANTCHARS + DLGC_WANTARROWS

      CASE WM_KEYDOWN
         //ProcKeyList(Self, wParam)
         IF wparam == VK_RIGHT .OR. wParam == VK_RETURN //.AND. !::lEdit
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ELSEIF wparam == VK_LEFT //.AND. !::lEdit
            GetSkip(::oParent, ::handle, , -1)
            RETURN 0
         ELSEIF wParam == VK_ESCAPE .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE //.OR. ;
            RETURN 0
         ENDIF
         EXIT

      CASE WM_KEYUP
         ProcKeyList(Self, wParam) //working in MDICHILD AND DIALOG
         EXIT

      CASE WM_COMMAND
         IF ::lEdit .AND. !::ldropshow
            IF GETKEYSTATE(VK_DOWN) + GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0 .AND. HiWord(wParam) == 1
               RETURN 0
            ENDIF
         ENDIF
         EXIT

      CASE CB_GETDROPPEDSTATE
         IF !::ldropshow
            IF GETKEYSTATE(VK_RETURN) < 0
               ::GetValue()
            ENDIF
            IF (GETKEYSTATE(VK_RETURN) < 0 .OR. GETKEYSTATE(VK_ESCAPE) < 0) .AND. ;
               (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
               !::GetParentForm(Self):lModal)
               ProcOkCancel(Self, IIf(GETKEYSTATE(VK_RETURN) < 0, VK_RETURN, VK_ESCAPE))
            ENDIF
            IF GETKEYSTATE(VK_TAB) + GETKEYSTATE(VK_DOWN) < 0 .AND. GetKeyState(VK_SHIFT) > 0
               IF ::oParent:oParent == NIL
                  //GetSkip(::oParent, GetAncestor(::handle, GA_PARENT), , 1)
               ENDIF
               GetSkip(::oParent, ::handle, , 1)
               RETURN 0
            ELSEIF GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0
               IF ::oParent:oParent == NIL
                  //GetSkip(::oParent, GetAncestor(::handle, GA_PARENT), , 1)
               ENDIF
               GetSkip(::oParent, ::handle, , -1)
               RETURN 0
            ENDIF
            IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
               RETURN 1
            ENDIF
         ENDIF

      ENDSWITCH

   ENDIF

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD MaxLength( nMaxLength ) CLASS HComboBox

   IF nMaxLength != Nil .AND. ::lEdit
       Sendmessage(::handle, CB_LIMITTEXT, nMaxLength, 0)
       ::nMaxLength := nMaxLength
   ENDIF

RETURN ::nMaxLength

//-------------------------------------------------------------------------------------------------------------------//

METHOD Requery() CLASS HComboBox

   SendMessage(::handle, CB_RESETCONTENT, 0, 0)
   ::Populate()

   /*
   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[i] )
   NEXT
   */
   //::Refresh()
   IF Empty( ::Value ) .AND. LEN( ::aItems ) > 0 .AND. ::bSetGet = Nil .AND. !::lEdit
      ::SetItem( 1 )
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HComboBox

   LOCAL vari

   IF hb_IsBlock(::bSetGet)
      vari := Eval( ::bSetGet,, Self )
      IF ::columnBound = 2
          vari := ::GetValueBound(vari)
      ENDIF
      IF ::columnBound = 1
         IF ::lText
         //vari := IIF( ::bSetGetField != Nil  .AND. hb_IsChar(vari), TRIM( vari ), vari )
            ::value := Iif( vari==Nil .OR. !hb_IsChar(vari), "", vari )
               //SendMessage(::handle, CB_SETEDITSEL, 0, LEN(::value))
         ELSE
            ::value := Iif( vari==Nil .OR. !hb_IsNumeric(vari), 1, vari )
         ENDIF
      ENDIF
      /*
      IF ::columnBound = 1
         Eval( ::bSetGet, ::value, Self )
      ELSE
         Eval( ::bSetGet, ::valuebound, Self )
      ENDIF
      */
   ENDIF

   /*
   SendMessage(::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[i] )
   NEXT
 */
   IF ::lText
      IF ::lEdit
         SetDlgItemText( getmodalhandle(), ::id, ::value)
         SendMessage(::handle, CB_SETEDITSEL, 0, ::SelStart)
      ENDIF
      #ifdef __XHARBOUR__
      ComboSetString( ::handle, AScan( ::aItems, ::value, , , .T.  ) )
      #else
      ComboSetString( ::handle, hb_AScan( ::aItems, ::value, , , .T.  ) )
      #endif
   ELSE
      ComboSetString( ::handle, ::value )
      //-::SetItem(::value )
   ENDIF
   ::valueBound := ::GetValueBound()

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetItem( nPos ) CLASS HComboBox

   /*
 IF hb_IsChar(nPos) .AND. ::lText
    nPos := AScan( ::aItems, nPos )
      ComboSetString( ::handle, nPos  )
   ENDIF
   */
   IF ::lText
      IF nPos > 0
         ::value := ::aItems[nPos]
         ::ValueBound := ::GetValueBound()
      ELSE
         ::value := ""
         ::valueBound := IIF( ::bSetGet != Nil, Eval( ::bSetGet,, Self ), ::valueBound )
      ENDIF
   ELSE
      ::value := nPos
      ::ValueBound := ::GetValueBound()
   ENDIF

   ComboSetString( ::handle, nPos )

   IF hb_IsBlock(::bSetGet)
      IF ::columnBound = 1
         Eval( ::bSetGet, ::value, Self )
      ELSE
         Eval( ::bSetGet, ::valuebound, Self )
      ENDIF
   ENDIF

   /*
   IF hb_IsBlock(::bChangeSel)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChangeSel, nPos, Self )
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   */

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetValue(xItem) CLASS HComboBox

   LOCAL nPos

   IF ::lText .AND. hb_IsChar(xItem)
      IF ::columnBound = 2
         nPos := AScan( ::aItemsBound, xItem )
      ELSE
         nPos := AScan( ::aItems, xItem )
      ENDIF
      ComboSetString( ::handle, nPos )
   ELSE
      nPos := IIF( ::columnBound = 2, AScan( ::aItemsBound, xItem ), xItem )
   ENDIF
   ::setItem( nPos )

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetValue() CLASS HComboBox

   LOCAL nPos := SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1

   //::value := Iif( ::lText, ::aItems[nPos], nPos )
   IF ::lText
       IF ( ::lEdit .OR. !hb_IsChar(::Value) ) .AND. nPos <= 1
           ::Value := GetEditText( ::oParent:handle, ::id )
           nPos := SendMessage(::handle, CB_FINDSTRINGEXACT, -1, ::value) + 1
        ELSEIF nPos > 0
         ::value := ::aItems[nPos]
      ENDIF
      //nPos := IIF( LEN( ::value ) > 0, AScan( ::aItems, ::Value ), 0 )
      ::cDisplayValue := ::Value
      ::value := Iif( nPos > 0, ::aItems[nPos], IIF( ::lEdit, "", ::value ) )
   ELSE
      ::value := nPos
   ENDIF
   ::ValueBound := IIF( nPos > 0, ::GetValueBound(), ::ValueBound ) // IIF( ::lText, "", 0 ) )
   IF hb_IsBlock(::bSetGet)
      IF ::columnBound = 1
         Eval( ::bSetGet, ::value, Self )
      ELSE
         Eval( ::bSetGet, ::ValueBound, Self )
      ENDIF
   ENDIF

RETURN ::value

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetValueBound(xItem) CLASS HComboBox

   LOCAL nPos := SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1

   IF ::columnBound = 1
      RETURN Nil
   ENDIF
   IF xItem = Nil
      IF ::lText
          //nPos := IIF( ::Value = Nil,0, AScan( ::aItems, ::Value ) )
          #ifdef __XHARBOUR__
          nPos := IIF( ::Value = Nil, 0, AScan( ::aItems, ::value, , , .T.  ) )
          #else
          nPos := IIF( ::Value = Nil, 0, hb_AScan( ::aItems, ::value, , , .T.  ) )
          #endif
      ENDIF
   ELSE
      //nPos := AScan( ::aItemsBound, xItem )
      #ifdef __XHARBOUR__
      nPos := AScan( ::aItemsBound, xItem, , , .T. )
      #else
      nPos := hb_AScan( ::aItemsBound, xItem, , , .T. )
      #endif
      ::setItem( nPos )
      RETURN IIF( nPos > 0, ::aItems[nPos], xItem )
   ENDIF
   //::ValueBound := IIF( ::lText, "", 0 )
   IF nPos > 0 .AND. nPos <=  LEN( ::aItemsBound ) // LEN( ::aItems ) = LEN( ::aItemsBound )
      ::ValueBound := ::aItemsBound[nPos]
   ENDIF

RETURN ::ValueBound

//-------------------------------------------------------------------------------------------------------------------//

METHOD DisplayValue(cValue) CLASS HComboBox

   IF cValue != Nil
       IF ::lEdit .AND. hb_IsChar(cValue)
         SetDlgItemText( ::oParent:handle, ::id, cValue )
         ::cDisplayValue := cValue
      ENDIF
   ENDIF

RETURN IIF( !::lEdit, GetEditText( ::oParent:handle, ::id ), ::cDisplayValue )
//RETURN IIF( IsWindow( ::oParent:handle ), GetEditText( ::oParent:handle, ::id ), ::cDisplayValue )

//-------------------------------------------------------------------------------------------------------------------//

METHOD DeleteItem( xIndex ) CLASS HComboBox

   LOCAL nIndex

   IF ::lText .AND. hb_IsChar(xIndex)
         nIndex := SendMessage(::handle, CB_FINDSTRINGEXACT, -1, xIndex) + 1
   ELSE
       nIndex := xIndex
   ENDIF
   IF SendMessage(::handle, CB_DELETESTRING, nIndex - 1, 0) > 0               //<= LEN(ocombo:aitems)
      Adel( ::Aitems, nIndex )
      Asize(::Aitems, Len( ::aitems ) - 1)
      IF LEN( ::AitemsBound ) > 0
         ADEL( ::AitemsBound, nIndex )
         ASIZE(::AitemsBound, Len( ::aitemsBound ) - 1)
      ENDIF
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddItem( cItem, cItemBound, nPos ) CLASS HComboBox

   LOCAL nCount

   nCount := SendMessage(::handle, CB_GETCOUNT, 0, 0) + 1
   IF LEN( ::Aitems ) == LEN( ::AitemsBound ) .AND. cItemBound != NIL
      IF nCount = 1
         ::RowSource({{cItem, cItemBound}})
         ::Aitems := {}
      ENDIF
      IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
         aSize(::AitemsBound, nCount + 1)
         aIns( ::AitemsBound, nPos, cItemBound )
      ELSE
         AADD(::AitemsBound, cItemBound)
      ENDIF
      ::columnBound := 2
   ENDIF
   IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
       aSize(::Aitems, nCount + 1)
       aIns( ::Aitems, nPos, cItem )
    ELSE
       AADD(::Aitems, cItem)
    ENDIF
    IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
       ComboInsertString( ::handle, nPos - 1, cItem )  //::aItems[i] )
    ELSE
       ComboAddString( ::handle, cItem)  //::aItems[i] )
    ENDIF

RETURN nCount

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetCueBanner( cText, lShowFoco ) CLASS HComboBox

   LOCAL lRet := .F.

   IF ::lEdit
      lRet := SendMessage(::Handle, CB_SETCUEBANNER, IIF(EMPTY(lShowFoco), 0, 1), ANSITOUNICODE(cText))
   ENDIF

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

METHOD InteractiveChange() CLASS HComboBox

   LOCAL npos

   npos := SendMessage(::handle, CB_GETEDITSEL, 0, 0)
   ::SelStart := nPos
   ::cDisplayValue := GetWindowText(::handle)
   ::oparent:lSuspendMsgsHandling := .T.
   Eval(::bChangeInt, ::value, Self)
   ::oparent:lSuspendMsgsHandling := .F.
   SendMessage(::handle, CB_SETEDITSEL, 0, ::SelStart)

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD onSelect() CLASS HComboBox

   IF hb_IsBlock(::bSelect)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bSelect, ::value, Self )
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD onChange(lForce) CLASS HComboBox

   IF !SelfFocus(::handle) .AND. Empty( lForce )
      RETURN Nil
   ENDIF
   IF !isWindowVisible(::handle)
      ::SetItem( ::Value )
      RETURN Nil
   ENDIF

   ::SetItem( SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1 )
   IF hb_IsBlock(::bChangeSel)
      //::SetItem( SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1 )
      ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChangeSel, ::Value, Self )
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD When() CLASS HComboBox

   LOCAL res := .T.
   LOCAL oParent
   LOCAL nSkip

   IF !CheckFocus( Self, .F. )
      RETURN .T.
   ENDIF

   IF !::lText
      //::Refresh()
   ELSE
      //  SetWindowText(::handle, ::value)
      //  SendMessage(::handle, CB_SELECTSTRING, 0, ::value)
   ENDIF
   nSkip := Iif( GetKeyState(VK_UP) < 0 .OR. ( GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0 ), - 1, 1 )
   IF hb_IsBlock(::bGetFocus)
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      IF hb_IsBlock(::bSetGet)
         res := Eval( ::bGetFocus, Eval( ::bSetGet,, Self ), Self )
      ELSE
         res := Eval( ::bGetFocus, ::value, Self )
      ENDIF
      ::oParent:lSuspendMsgsHandling := .F.
      ::lnoValid := !res
      IF hb_IsLogical(res) .AND. !res
         oParent := ParentGetDialog( Self )
         IF Self == ATail( oParent:GetList )
            nSkip := - 1
         ELSEIF Self == oParent:getList[1]
            nSkip := 1
         ENDIF
         WhenSetFocus( Self, nSkip )
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD Valid() CLASS HComboBox

   LOCAL oDlg
   LOCAL nSkip
   LOCAL res
   LOCAL hCtrl := getfocus()
   LOCAL ltab := GETKEYSTATE(VK_TAB) < 0

   IF ::lNoValid .OR. !CheckFocus( Self, .T. )
      RETURN .T.
   ENDIF

   nSkip := Iif( GetKeyState(VK_SHIFT) < 0, - 1, 1 )

   IF ( oDlg := ParentGetDialog( Self ) ) == Nil .OR. oDlg:nLastKey != VK_ESCAPE
      // end by sauli
      // IF lESC // "if" by Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com.br) 03/06/2006
      ::GetValue()
      IF hb_IsBlock(::bLostFocus)
         ::oparent:lSuspendMsgsHandling := .T.
         res := Eval( ::bLostFocus, ::value, Self )
         IF hb_IsLogical(res) .AND. !res
            ::SetFocus( .T. )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            ::oparent:lSuspendMsgsHandling := .F.
            RETURN .F.
         ENDIF

      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
      IF lTab .AND. SelfFocus( hCtrl ) .AND. !SelfFocus( ::oParent:handle, oDlg:Handle )
        // IF ::oParent:CLASSNAME = "HTAB"
            ::oParent:SETFOCUS()
            Getskip(::oparent, ::handle, , nSkip)
       //  ENDIF
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF Empty( GETFOCUS() ) // getfocus return pointer = 0                 //::nValidSetfocus = ::handle
         GetSkip(::oParent, ::handle, , ::nGetSkip)
      ENDIF
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD RowSource(xSource) CLASS HComboBox

   IF xSource != Nil
      IF hb_IsArray(xSource)
        IF LEN( xSource ) > 0 .AND. !hb_IsArray( xSource[1] ) .AND. LEN( xSource ) <= 2 .AND. "->" $ xSource[1] // COLUMNS MAX = 2
           ::xrowsource := {xSource[1], IIF(LEN(xSource) > 1, xSource[2], Nil)}
        ENDIF
      ELSE
         ::xrowsource := {xSource, Nil}
      ENDIF
      ::aItems := xSource
   ENDIF

RETURN ::xRowSource

//-------------------------------------------------------------------------------------------------------------------//

METHOD Populate() CLASS HComboBox

   LOCAL cAlias
   LOCAL nRecno
   LOCAL value
   LOCAL cValueBound
   LOCAL i
   LOCAL numofchars
   LOCAL LongComboWidth := 0
   LOCAL xRowSource

   IF EMPTY( ::aItems )
      RETURN Nil
   ENDIF
   xRowSource := iif( hb_IsArray( ::xRowSource[1] ), ::xRowSource[1, 1], ::xRowSource[1] )
   IF xRowSource != Nil .AND. ( i := At( "->", xRowSource ) ) > 0
       cAlias := AlLTRIM( LEFT( xRowSource, i - 1 ) )
       IF Select( cAlias ) = 0 .AND. ( i := At( "(", cAlias ) ) > 0
          cAlias := LTRIM( SUBSTR( cAlias, i + 1 ) )
       ENDIF
      value := STRTRAN( xRowSource, calias + "->", , , 1, 1 )
      cAlias := IIF( VALTYPE(xRowSource) == "U", Nil, cAlias )
      cValueBound := IIF( ::xrowsource[2]  != Nil  .AND. cAlias != Nil, STRTRAN( ::xrowsource[2], calias + "->" ), Nil )
   ELSE
      cValueBound := IIF( hb_IsArray(::aItems[1]) .AND. LEN(  ::aItems[1] ) > 1, ::aItems[1, 2], NIL )
   ENDIF
   ::columnBound := IIF( cValueBound = Nil, 1, 2 )
   IF ::value == Nil
      IF ::lText
         ::value := IIF( cAlias = Nil, ::aItems[1], ( cAlias )-> ( &( value ) ) )
       ELSE
         ::value := 1
       ENDIF
   ELSEIF ::lText .AND. !::lEdit .AND. EMPTY ( ::value )
      ::value := IIF( cAlias = Nil, ::aItems[1], ( cAlias )-> ( &( value ) ) )
   ENDIF
   SendMessage(::handle, CB_RESETCONTENT, 0, 0)
   ::AitemsBound := {}
   IF cAlias != Nil .AND. SELECT( cAlias ) > 0
      ::aItems := {}
      nRecno := ( cAlias ) ->( Recno() )
      ( cAlias ) ->( DBGOTOP() )
       i := 1
       DO WHILE !( cAlias ) ->( EOF() )
         AADD(::Aitems,( cAlias ) -> ( &( value ) ))
         IF !EMPTY( cvaluebound )
            AADD(::AitemsBound,( cAlias ) -> ( &( cValueBound ) ))
         ENDIF
         ComboAddString( ::handle, ::aItems[i] )
         numofchars := SendMessage(::handle, CB_GETLBTEXTLEN, i - 1, 0)
         IF numofchars > LongComboWidth
             LongComboWidth := numofchars
         ENDIF
         ( cAlias ) ->( DBSKIP() )
         i ++
       ENDDO
       IF nRecno > 0
          ( cAlias ) ->( DBGOTO( nRecno ) )
       ENDIF
    ELSE
       FOR i := 1 TO Len( ::aItems )
          IF ::columnBound > 1
             IF hb_IsArray(::aItems[i]) .AND. LEN(  ::aItems[i] ) > 1
                AADD(::AitemsBound, ::aItems[i, 2 ])
             ELSE
                AADD(::AitemsBound, Nil)
             ENDIF
             ::aItems[i] := ::aItems[i, 1]
             ComboAddString( ::handle, ::aItems[i] )
          ELSE
             ComboAddString( ::handle, ::aItems[i] )
          ENDIF
          numofchars := SendMessage(::handle,CB_GETLBTEXTLEN, i - 1, 0 )
          if numofchars > LongComboWidth
              LongComboWidth := numofchars
          endif
       NEXT
    ENDIF
    ::ValueBound := ::GetValueBound()

RETURN LongComboWidth

//-------------------------------------------------------------------------------------------------------------------//

CLASS HCheckComboBox INHERIT HComboBox

   CLASS VAR winclass INIT "COMBOBOX"
   DATA m_bTextUpdated INIT .F.

   DATA m_bItemHeightSet INIT .F.
   DATA m_hListBox INIT 0
   DATA aCheck
   DATA nWidthCheck INIT 0
   DATA m_strText INIT ""
   METHOD onGetText( wParam, lParam )
   METHOD OnGetTextLength( wParam, lParam )

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
   aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, ;
   tcolor, bcolor, bValid, acheck, nDisplay, nhItem, ncWidth )
   METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, ctooltip, bGFocus, acheck)
   METHOD INIT()
   METHOD Requery()
   METHOD Refresh()
   METHOD Paint( lpDis )
   METHOD SetCheck( nIndex, bFlag )
   METHOD RecalcText()

   METHOD GetCheck( nIndex )

   METHOD SelectAll( bCheck )
   METHOD MeasureItem( l )

   METHOD onEvent( msg, wParam, lParam )
   METHOD GetAllCheck()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
               bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, ;
               bValid, acheck, nDisplay, nhItem, ncWidth ) CLASS hCheckComboBox

   ::acheck := Iif( acheck == Nil, {}, acheck )
   IF hb_IsNumeric(nStyle)
      nStyle := hwg_multibitor( nStyle, CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ELSE
      nStyle := hwg_multibitor( CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ENDIF

   bPaint := {|o, p|o:paint(p)}

   ::Super:New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
                bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid,, nDisplay, nhItem, ncWidth )

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, ctooltip, bGFocus, acheck) CLASS hCheckComboBox

   ::Super:Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                     bChange, ctooltip, bGFocus)
   ::lResource := .T.
   ::acheck := acheck

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference
METHOD onEvent( msg, wParam, lParam ) CLASS hCheckComboBox

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
      ::MeasureItem( lParam )
      RETURN 0
   ELSEIF msg == WM_GETTEXT
      RETURN ::OnGetText( wParam, lParam )

   ELSEIF msg == WM_GETTEXTLENGTH

      RETURN ::OnGetTextLength( wParam, lParam )

   ELSEIF msg == WM_CHAR
      IF ( wParam == VK_SPACE )

         nIndex := SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )
         InvalidateRect( ::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4] )
         ::SetCheck( nIndex, !::GetCheck( nIndex ) )
         SendMessage(::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle)
      ENDIF
      IF ( ::GetParentForm( Self ) :Type < WND_DLG_RESOURCE .OR. !::GetParentForm( Self ) :lModal )
         IF wParam = VK_TAB
            GetSkip(::oParent, ::handle,, Iif( IsCtrlShift( .F., .T. ), -1, 1) )
            RETURN 0
         ELSEIF wParam == VK_RETURN
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg = WM_KEYDOWN
      ProcKeyList( Self, wParam )

   ELSEIF msg == WM_LBUTTONDOWN

      rcClient := GetClientRect(::handle)

      pt := {, }
      pt[1] = LOWORD(lParam)
      pt[2] = HIWORD(lParam)

      IF ( PtInRect( rcClient, pt ) )

         nItemHeight := SendMessage(::handle, LB_GETITEMHEIGHT, 0, 0)
         nTopIndex := SendMessage(::handle, LB_GETTOPINDEX, 0, 0)

         // Compute which index to check/uncheck
         nIndex := ( nTopIndex + pt[2] / nItemHeight ) + 1
         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )

         //IF ( PtInRect( rcItem, pt ) )
         IF pt[1] < ::nWidthCheck
            // Invalidate this window
            InvalidateRect( ::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4] )
            nIndex := SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
            ::SetCheck( nIndex, !::GetCheck( nIndex ) )

            // Notify that selection has changed

            SendMessage(::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle)

         ENDIF
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      RETURN -1    //0
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS hCheckComboBox

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
         nIndex := SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
         rcItem := COMBOGETITEMRECT(::handle, nIndex - 1)
         InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
         ::SetCheck(nIndex, !::GetCheck(nIndex))
         SendMessage(::oParent:handle, WM_COMMAND, MAKELONG(::id, CBN_SELCHANGE), ::handle)
      ENDIF
      IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
         IF wParam == VK_TAB
            GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wParam == VK_RETURN
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
      RETURN 0

   CASE WM_KEYDOWN
      ProcKeyList(Self, wParam)
      EXIT

   CASE WM_LBUTTONDOWN
      rcClient := GetClientRect(::handle)
      pt := {,}
      pt[1] = LOWORD(lParam)
      pt[2] = HIWORD(lParam)
      IF PtInRect(rcClient, pt)
         nItemHeight := SendMessage(::handle, LB_GETITEMHEIGHT, 0, 0)
         nTopIndex := SendMessage(::handle, LB_GETTOPINDEX, 0, 0)
         // Compute which index to check/uncheck
         nIndex := (nTopIndex + pt[2] / nItemHeight) + 1
         rcItem := COMBOGETITEMRECT(::handle, nIndex - 1)
         //IF PtInRect(rcItem, pt)
         IF pt[1] < ::nWidthCheck
            // Invalidate this window
            InvalidateRect(::handle, .F., rcItem[1], rcItem[2], rcItem[3], rcItem[4])
            nIndex := SendMessage(::handle, CB_GETCURSEL, wParam, lParam) + 1
            ::SetCheck(nIndex, !::GetCheck(nIndex))
            // Notify that selection has changed
            SendMessage(::oParent:handle, WM_COMMAND, MAKELONG(::id, CBN_SELCHANGE), ::handle)
         ENDIF
      ENDIF
      EXIT

   CASE WM_LBUTTONUP
      RETURN -1 //0

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS hCheckComboBox

   LOCAL i

   //::nHolder := 1
   //SetWindowObject(::handle, Self)  // because hcombobox is handling
   //HWG_INITCOMBOPROC(::handle)
   IF !::lInit
      ::Super:Init()
      IF Len( ::acheck ) > 0
         FOR i := 1 TO Len( ::acheck )
            ::Setcheck( ::acheck[i], .T. )
         NEXT
      ENDIF
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD Requery() CLASS hCheckComboBox

   LOCAL i

   ::super:Requery()
   IF Len( ::acheck ) > 0
      FOR i := 1 TO Len( ::acheck )
         ::Setcheck( ::acheck[i], .T. )
      NEXT
   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS hCheckComboBox

   ::Super:refresh()

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetCheck( nIndex, bFlag ) CLASS hCheckComboBox

   LOCAL nResult := COMBOBOXSETITEMDATA(::handle, nIndex - 1, bFlag)

   IF ( nResult < 0 )
      RETURN nResult
   ENDIF

   ::m_bTextUpdated := FALSE

   // Redraw the window
   InvalidateRect( ::handle, 0 )

RETURN nResult

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetCheck( nIndex ) CLASS hCheckComboBox

   LOCAL l := COMBOBOXGETITEMDATA(::handle, nIndex - 1)

RETURN IF( l == 1, .T., .F. )

//-------------------------------------------------------------------------------------------------------------------//

METHOD SelectAll( bCheck ) CLASS hCheckComboBox

   LOCAL nCount
   LOCAL i

   DEFAULT bCheck TO .T.

   nCount := SendMessage(::handle, CB_GETCOUNT, 0, 0)

   FOR i := 1 TO nCount
      ::SetCheck( i, bCheck )
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD RecalcText() CLASS hCheckComboBox

   LOCAL strtext
   LOCAL ncount
   LOCAL strSeparator
   LOCAL i
   LOCAL stritem

   IF ( !::m_bTextUpdated )

      // Get the list count
      ncount := SendMessage(::handle, CB_GETCOUNT, 0, 0)

      // Get the list separator

      strSeparator := GetLocaleInfo()

      // If none found, the the ''
      IF Len( strSeparator ) == 0
         strSeparator := ''
      ENDIF

      strSeparator := Rtrim( strSeparator )

      strSeparator += ' '

      FOR i := 1 TO ncount

         IF ( COMBOBOXGETITEMDATA(::handle, i) ) = 1

            COMBOBOXGETLBTEXT( ::handle, i, @stritem )

            IF !Empty( strtext )
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

METHOD Paint( lpDis ) CLASS hCheckComboBox

   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL dc := drawInfo[3]
   LOCAL rcBitmap := {drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]}
   LOCAL rcText := {drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]}
   LOCAL strtext := ""
   LOCAL ncheck
   LOCAL metrics
   LOCAL nstate

   IF ( drawInfo[1] < 0 )

      ::RecalcText()

      strtext := ::m_strText

      ncheck := 0

   ELSE
      COMBOBOXGETLBTEXT( ::handle, drawInfo[1], @strtext )

      ncheck := 1 + ( COMBOBOXGETITEMDATA(::handle, drawInfo[1]) )

      metrics := GETTEXTMETRIC(dc)

      rcBitmap[1] := 0
      rcBitmap[3] := rcBitmap[1] + metrics[1] + metrics[4] + 6
      rcBitmap[2] += 1
      rcBitmap[4] -= 1

      rcText[1] := rcBitmap[3]
      ::nWidthCheck := rcBitmap[3]
   ENDIF

   IF ( ncheck > 0 )
      SetBkColor(dc, GetSysColor(COLOR_WINDOW))
      SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT))

      nstate := DFCS_BUTTONCHECK

      IF ( ncheck > 1 )
         nstate := hwg_bitor( nstate, DFCS_CHECKED )
      ENDIF

      // Draw the checkmark using DrawFrameControl
      DrawFrameControl( dc, rcBitmap, DFC_BUTTON, nstate )
   ENDIF

   IF ( hwg_Bitand(drawInfo[9], ODS_SELECTED) != 0 )
      SetBkColor(dc, GetSysColor(COLOR_HIGHLIGHT))
      SetTextColor(dc, GetSysColor(COLOR_HIGHLIGHTTEXT))

   ELSE
      SetBkColor(dc, GetSysColor(COLOR_WINDOW))
      SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT))
   ENDIF

   // Erase and draw
   IF Empty( strtext )
      strtext := ""
   ENDIF

   ExtTextOut( dc, 0, 0, rcText[1], rcText[2], rcText[3], rcText[4] )

   DrawText( dc, ' ' + strtext, rcText[1], rcText[2], rcText[3], rcText[4], DT_SINGLELINE + DT_VCENTER + DT_END_ELLIPSIS )

   IF ( ( hwg_Bitand(drawInfo[9], ODS_FOCUS + ODS_SELECTED) ) == ( ODS_FOCUS + ODS_SELECTED ) )
      DrawFocusRect( dc, rcText )
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD MeasureItem( l ) CLASS hCheckComboBox

   LOCAL dc := HCLIENTDC():new(::handle)
   LOCAL lpMeasureItemStruct := GETMEASUREITEMINFO( l )
   LOCAL metrics
   LOCAL pFont

   //pFont := dc:SelectObject(IIf(hb_IsObject(::oFont), ::oFont:handle, ::oParent:oFont:handle))
   pFont := dc:SelectObject(IIf(hb_IsObject(::oFont), ::oFont:handle, ;
      IIf(hb_IsObject(::oParent:oFont), ::oParent:oFont:handle,)))

   IF !Empty( pFont )

      metrics := dc:GetTextMetric()

      lpMeasureItemStruct[5] := metrics[1] + metrics[4]

      lpMeasureItemStruct[5] += 2

      IF ( !::m_bItemHeightSet )
         ::m_bItemHeightSet := .T.
         SendMessage(::handle, CB_SETITEMHEIGHT, - 1, MAKELONG( lpMeasureItemStruct[5], 0 ))
      ENDIF

      dc:SelectObject(pFont)
      dc:END()
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD OnGetText( wParam, lParam ) CLASS hCheckComboBox

   ::RecalcText()

   IF ( lParam == 0 )
      RETURN 0
   ENDIF

   // Copy the 'fake' window text
   copydata(lParam, ::m_strText, wParam)

RETURN Iif( Empty( ::m_strText ), 0, Len( ::m_strText ) )

//-------------------------------------------------------------------------------------------------------------------//

METHOD OnGetTextLength( WPARAM, LPARAM ) CLASS hCheckComboBox

   HB_SYMBOL_UNUSED(WPARAM)
   HB_SYMBOL_UNUSED(LPARAM)

   ::RecalcText()

RETURN Iif( Empty( ::m_strText ), 0, Len( ::m_strText ) )

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetAllCheck() CLASS hCheckComboBox

   LOCAL aCheck := {}
   LOCAL n

   FOR n := 1 TO Len( ::aItems )
      Aadd(aCheck, ::GetCheck( n ))
   NEXT

RETURN aCheck

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION hwg_multibitor( ... )

   LOCAL aArgumentList := HB_AParams()
   LOCAL nItem
   LOCAL result := 0

   FOR EACH nItem IN aArgumentList
      IF !hb_IsNumeric(nItem)
         msginfo( "hwg_multibitor parameter not numeric set to zero", "Possible error" )
         nItem := 0
      ENDIF
      result := hwg_bitor( result, nItem )
   NEXT

RETURN result

//-------------------------------------------------------------------------------------------------------------------//
