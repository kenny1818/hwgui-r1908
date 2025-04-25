#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog

   WITH OBJECT oDialog := MyDialog():new()
      :title   := "My dialog window"
      :nWidth  := 320
      :nHeight := 240
      :myMethod()
      :activate()
   ENDWITH

RETURN NIL

#include <hbclass.ch>

CLASS MyDialog FROM HDialog

   DATA oLabelId
   DATA oEditId
   DATA oLabelName
   DATA oEditName
   DATA oLabelPhone
   DATA oEditPhone
   DATA oButtonOK
   DATA oButtonCancel

   METHOD myMethod

ENDCLASS

METHOD myMethod() CLASS MyDialog

   WITH OBJECT ::oLabelId := HStatic():new()
      :title   := "Id"
      :nLeft   := 20
      :nTop    := 20
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oEditId := HEdit():new()
      :title   := "Id"
      :nLeft   := 120
      :nTop    := 20
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oLabelName := HStatic():new()
      :title   := "Name"
      :nLeft   := 20
      :nTop    := 60
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oEditName := HEdit():new()
      :title   := "Name"
      :nLeft   := 120
      :nTop    := 60
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oLabelPhone := HStatic():new()
      :title   := "Phone"
      :nLeft   := 20
      :nTop    := 100
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oEditPhone := HEdit():new()
      :title   := "Phone"
      :nLeft   := 120
      :nTop    := 100
      :nWidth  := 120
      :nHeight := 30
   ENDWITH

   WITH OBJECT ::oButtonOK := HButton():new()
      :title  := "&OK"
      :nLeft  := 20
      :nTop   := 140
      :bClick := {||hwg_MsgInfo("OK clicked", "Information")}
   ENDWITH

   WITH OBJECT ::oButtonCancel := HButton():new()
      :title  := "&Cancel"
      :nLeft  := 120
      :nTop   := 140
      :bClick := {||hwg_MsgInfo("Cancel clicked", "Information")}
   ENDWITH

RETURN NIL
