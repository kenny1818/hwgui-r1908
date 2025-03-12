//
// $Id: hpanel.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Linux (GTK) GUI library source code:
// HPanel class
//
// Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include <hbclass.ch>
#include "guilib.ch"

CLASS HPanel INHERIT HControl

   DATA winclass   INIT "PANEL"

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Move( x1,y1,width,height )

ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  bInit,bSize,bPaint,lDocked ) CLASS HPanel
Local oParent:=IIf(oWndParent == NIL, ::oDefaultParent, oWndParent)

   nStyle := SS_OWNERDRAW
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,IIf(nWidth == NIL, 0, nWidth), ;
                  nHeight,oParent:oFont,bInit, ;
                  bSize,bPaint )

   ::bPaint  := bPaint

   ::Activate()

Return Self

METHOD Activate CLASS HPanel

   IF !Empty(::oParent:handle)
      ::handle := hwg_CreatePanel( ::oParent:handle, ::id, ;
                   ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()
   ELSE
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

Return 0

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil
         IF ::nHeight!=0 .AND. ( ::nWidth>::nHeight .OR. ::nWidth==0 )
            ::bSize := {|o,x,y|o:Move( ,IIf(::nTop > 0, y - ::nHeight, 0),x,::nHeight )}
         ELSEIF ::nWidth!=0 .AND. ( ::nHeight>::nWidth .OR. ::nHeight==0 )
            ::bSize := {|o,x,y|o:Move( IIf(::nLeft > 0, x - ::nLeft, 0),,::nWidth,y )}
         ENDIF
      ENDIF

      ::Super:Init()
      hwg_SetWindowObject( ::handle,Self )
   ENDIF

Return Nil

METHOD Paint() CLASS HPanel
Local hDC, aCoors, oPenLight, oPenGray

   IF ::bPaint != Nil
      Eval( ::bPaint,Self )
   ELSE
      hDC := GetDC( ::handle )
      hwg_DrawButton( hDC, 0,0,::nWidth-1,::nHeight-1,5 )
      releaseDC( ::handle, hDC )
   ENDIF

Return Nil

METHOD Move( x1,y1,width,height )  CLASS HPanel

   ::Super:Move( x1,y1,width,height,.T. )
Return Nil

