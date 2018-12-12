(* ::Package:: *)

(* Autogenerated Package *)

(* ::Section:: *)
(*Interfaces*)



(* ::Text:: *)
(*
	The idea for this package is that it will be used inside other packages to provide an easy, standard way to get all the nice OOP-like boilerplate in place that one generally would for an object based on an Association
*)



BeginPackage["InterfaceObjects`"];


RegisterInterface::usage=
  "Registers an object interface";


$InterfacePropertyStore::usage=
  "ExpressionStore for cached object properties";
InterfaceSetProperty::usage=
  "Sets a property value";
InterfacePropertyValue::usage=
  "Gets a property value";  
InterfaceRemoveProperty::usage=
  "Removes a property value";
InterfacePropertyList::usage=
  "Lists the properties on an object";
InterfaceCopyProperties::usage=
  "Copies properties from one object to another";


InterfaceMethod::usage=
  "Alias for defining object methods";
InterfaceAttribute::usage=
  "Alias for defining object attributes";
InterfaceOverride::usage=
  "Alias for defining object UpValues";


InterfaceModify::usage=
  "Replace keys in one interface with new values";
InterfaceAssociation::usage=
  "Extracts the underlying Association from an interface";


Begin["`Private`"];


(* ::Subsection:: *)
(*Properties*)



If[!ValueQ@$InterfacePropertyStore,
  $InterfacePropertyStore=Language`NewExpressionStore["<ObjectPropertyStore>"]
  ];


(* ::Subsubsection::Closed:: *)
(*get*)



propGet[spec_, prop_]:=
  Replace[$InterfacePropertyStore@"get"[spec, prop],
    {
      Null->Missing["KeyAbsent", prop],
      $$hold[x_]:>x
      }
    ];


(* ::Subsubsection::Closed:: *)
(*set*)



propSet[spec_, prop_, val_]:=
  (
    $InterfacePropertyStore@"put"[spec, prop, val];
    val
    )


(* ::Subsubsection::Closed:: *)
(*set*)



$$hold~SetAttributes~HoldAllComplete


propSetDelayed~SetAttributes~HoldRest


propSetDelayed[spec_, prop_, val_]:=
  (
    $InterfacePropertyStore@"put"[spec, prop, $$hold@val];
    )


(* ::Subsubsection::Closed:: *)
(*remove*)



propRemove[spec_, prop_]:=
  $InterfacePropertyStore@"remove"[spec, prop];


(* ::Subsubsection::Closed:: *)
(*keys*)



propKeys[spec__]:=
  $InterfacePropertyStore@"getKeys"[spec]


(* ::Subsubsection::Closed:: *)
(*computeProp*)



computeProp[spec_, prop_, func_, args___]:=
  Replace[propGet[spec, prop],
    Missing["KeyAbsent", prop]:>
      With[{v=func[args]},
        propSet[spec, prop, v];
        v
        ]
    ]
computeProp~SetAttributes~HoldAllComplete


(* ::Subsubsection::Closed:: *)
(*copyProps*)



copyProps[obj1_, obj2_, keyTest_:(True&)]:=
  Scan[If[keyTest[#], propSet[obj2, #, propGet[obj1, #]]]&, propKeys[obj1]]


(* ::Subsubsection::Closed:: *)
(*Properties*)



InterfaceSetProperty[spec_, prop_->val_]:=
  propSet[spec, prop, val];
InterfaceSetProperty[spec_, prop_:>val_]:=
  propSetDelayed[spec, prop, val];
InterfacePropertyValue[spec_, prop_]:=
  propGet[spec, prop];
InterfaceRemoveProperty[spec_, prop_]:=
  propRemove[spec, prop];
InterfacePropertyList[spec_]:=
  propKeys[spec]


(* ::Subsubsection::Closed:: *)
(*CopyProperties*)



InterfaceCopyProperties[obj1_, obj2_, keys_List]:=
  copyProps[obj1, obj2, AnyTrue[keys, With[{o=#}, #===o&]&]];
InterfaceCopyProperties[obj1_, obj2_, e_]:=
  copyProps[obj1, obj2, e]


(* ::Subsection:: *)
(*RegisterInterface*)



(* ::Text:: *)
(*
	This function makes it really easy to create a new object and avoid the boilerplate
*)



(* ::Subsubsection::Closed:: *)
(*Defaults*)



(* ::Subsubsubsection::Closed:: *)
(*defaultConstructorFailureFunction*)



If[Length@DownValues[PackageRaiseException]>0,
  defaultConstructorFailureFunction[head_, args__]:=
    PackageRaiseException[Automatic,
      "Failed to build `` object from data ``",
      head,
      HoldForm[{args}]
      ],
  defaultConstructorFailureFunction[head_, args__]:=
    Failure["BuildFailure",
      <|
        "MessageTemplate"->"Failed to build `` object from data ``",
        "MessageParameters"->{head, HoldForm[{args}]}
        |>
      ]
  ];
defaultConstructorFailureFunction~SetAttributes~HoldAllComplete;


(* ::Subsubsubsection::Closed:: *)
(*createConstructor*)



createConstructor[constructor_, keys_]:=
  (
    constructor[a_Association]:=
      If[Length@keys>1||Length@keys===1&&KeyExistsQ[a, keys[[1]]],
        a,
        Quiet[AssociationThread[keys, {a}], AssociationThread::idim]
        ];
    constructor[args__]:=
      Quiet[AssociationThread[keys, {args}], AssociationThread::idim]
    )


(* ::Subsubsubsection::Closed:: *)
(*createAccessorFunctions*)



createAccessorFunctions[head_, headQ_]:=
  Module[
    {
      key,
      part
      },
    part[HoldPattern[head[a_]?headQ], k_String, p___]:=
      With[{res=Quiet[a[[k, p]], Part::partd]}, res/;Head[res]=!=Part];
    key[HoldPattern[head[a_]?headQ], k__]:=
      a[k];
    <|"Keys"->key, "Parts"->part|>
    ]


(* ::Subsubsubsection::Closed:: *)
(*createMutationHandlers*)



(* ::Text:: *)
(*	
	Need to finish this up so I can have automatic creation of mutation handlers for the default case of wanting all basic mutations based on Set and stuff
*)



createMutationHandlers[
  head_,
  headQ_,
  handlers_List
  ]:=
  Module[
    {
      res=<||>,
      selfMutate,
      keyMutate,
      partMutate,
      selfDispatch,
      keyDispatch,
      partDispatch
      },
    If[MemberQ[handlers, "Self"],
      selfMutate[
        h_,
        HoldPattern[head[a_]?headQ],
        args___
        ]:=
        Block[{core=a},
          h[core["Value"], args];
          head@core
          ];
      selfDispatch[h_]:=
        Function[Null, selfMutate[h, ##], HoldAllComplete];
      res["Self"]=selfDispatch;
      ];
    If[MemberQ[handlers, "Keys"],
      keyMutate[
        h_,
        HoldPattern[head[a_]?headQ],
        {k__},
        args___
        ]:=
        Block[{core=a},
          h[core[k], args];
          head@core
          ];
      keyDispatch[h_]:=
        Function[Null, keyMutate[h, ##], HoldAllComplete];
      res["Keys"]=keyDispatch;
      ];
    If[MemberQ[handlers, "Parts"],
      partMutate[
        h_,
        HoldPattern[head[a_]?headQ],
        {p__},
        args___
        ]:=
        Block[{core=a},
          h[core[[p]], args];
          head@core
          ];
      partDispatch[h_]:=
        Function[Null, partMutate[h, ##], HoldAllComplete];
      res["Parts"]=partDispatch;
      ];
    res
    ]
      


(* ::Subsubsection::Closed:: *)
(*RegisterInterface*)



Options[RegisterInterface]=
  {
    "Version"->1,
    "Atomic"->True,
    "Validator"->Automatic,
    "Constructor"->Automatic,
    "MutationHandler"->Automatic,
    "MutationFunctions"->None,
    "Protect"->False,
    "AccessorFunctions"->Automatic,
    "NormalFunction"->Automatic,
    "Formatted"->True,
    "Icon"->None,
    "DefaultMethods"->{
      Association, Keys, Values, SetProperty, PropertyValue,
      RemoveProperty, PropertyList
      },
    "DefaultAttributes"->{
      "Properties", "Methods"
      }
    };
RegisterInterface[
  head_,
  keys_,
  ops:OptionsPattern[]
  ]:=
  Module[
    {
      entryQ=True@OptionValue["Atomic"],
      ctor=OptionValue["Constructor"],
      constructor,
      ctorFail=defaultConstructorFailureFunction,
      ctorFailOnUndef=False,
      vdtor=OptionValue["Validator"],
      objQ,
      version=OptionValue["Version"],
      muh=OptionValue["MutationHandler"],
      mutationHandler,
      mud=OptionValue["MutationFunctions"],
      acc=OptionValue["AccessorFunctions"],
      norm=
        Replace[OptionValue["NormalFunction"],
          Automatic:>(KeyDrop[#, "Version"]&)
          ],
      format=OptionValue["Formatted"],
      icon=OptionValue["Icon"]
      },
    iRegisterInterfaceEntryQ[
      head,
      !entryQ
      ];
    If[vdtor===Automatic, vdtor=objQ];
    iRegisterInterfaceValidator[head, keys, vdtor];
    Which[
      ctor===Automatic,
        createConstructor[constructor, keys];
        ctor=constructor,
      Head[ctor]===Symbol&&DownValues[Evaluate@ctor]=={},
        createConstructor[ctor, keys],
      AssociationQ@ctor,
        ctorFail=
          Lookup[ctor, "FailureFunction", ctorFail];
        ctorFailOnUndef=
          Lookup[ctor, "FailOnUndefined", ctorFailOnUndef];
        ctor=ctor["Function"]
      ];
    iRegisterInterfaceConstructor[
      head,
      version,
      ctor,
      ctorFail,
      ctorFailOnUndef
      ];
    If[mud=!=None,
      If[mud===Automatic, mud={"Self", "Keys", "Parts"}];
      If[ListQ@mud,
        mud=createMutationHandlers[head, vdtor, mud];
        ];
      If[muh===Automatic,
        muh=mutationHandler
        ];
      iRegisterInterfaceMutationHandler[
        head,
        mutationHandler,
        mud
        ]
      ];
    If[acc=!=None,
      Which[
        acc===Automatic,
          iRegisterInterfaceAccessor[head, createAccessorFunctions[head, vdtor]],
        acc==="Keys",
          iRegisterInterfaceAccessor[head, 
            KeyDrop["Parts"]@createAccessorFunctions[head, vdtor]
            ],
        acc==="Parts",
          iRegisterInterfaceAccessor[head, 
            KeyDrop["Keys"]@createAccessorFunctions[head, vdtor]
            ],
        True,
          iRegisterInterfaceAccessor[head, acc]
        ]
      ];
    If[norm=!=None,
      iRegisterInterfaceNormalForm[head, norm]
      ];
    If[format,
      iRegisterInterfaceFormatting[head, icon]
      ];
    iRegisterDefaultInterfaceMethods[head, OptionValue["DefaultMethods"]];
    iRegisterDefaultInterfaceAttributes[head, OptionValue["DefaultAttributes"]];
    If[OptionValue["Protect"], Protect[head]];
    head
    ];


(* ::Subsubsection::Closed:: *)
(*$InterfaceData*)



(* ::Subsubsubsection::Closed:: *)
(*$InterfaceData*)



If[!ValueQ@$InterfaceData,
  $InterfaceData=Language`NewExpressionStore["<ObjectDataStore>"]
  ];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceConstructor*)



InterfaceConstructor/:
  (InterfaceConstructor[head_]=fn_):=
    $InterfaceData@"put"[head, "Constructor", fn];
InterfaceConstructor[head_]:=
  $InterfaceData@"get"[head, "Constructor"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceValidator*)



InterfaceValidator/:
  (InterfaceValidator[head_]=fn_):=
    $InterfaceData@"put"[head, "Validator", fn];
InterfaceValidator[head_]:=
  $InterfaceData@"get"[head, "Validator"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceCheckValid*)



InterfaceCheckValid/:
  (InterfaceCheckValid[head_]=fn_):=
    $InterfaceData@"put"[head, "CheckValid", fn];
InterfaceCheckValid[head_]:=
  $InterfaceData@"get"[head, "CheckValid"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceCheckInvalid*)



InterfaceCheckInvalid/:
  (InterfaceCheckInvalid[head_]=fn_):=
    $InterfaceData@"put"[head, "CheckInvalid", fn];
InterfaceCheckInvalid[head_]:=
  $InterfaceData@"get"[head, "CheckInvalid"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceSetValid*)



InterfaceSetValid/:
  (InterfaceSetValid[head_]=fn_):=
    $InterfaceData@"put"[head, "SetValid", fn];
InterfaceSetValid[head_]:=
  $InterfaceData@"get"[head, "SetValid"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceMethods*)



InterfaceMethods/:
  (InterfaceMethods[head_]=meths_):=
    $InterfaceData@"put"[head, "Methods", meths];
InterfaceMethods[head_]:=
  If[#===Null, <||>, #]&@$InterfaceData@"get"[head, "Methods"];


(* ::Subsubsubsection::Closed:: *)
(*InterfaceAttributes*)



InterfaceAttributes/:
  (InterfaceAttributes[head_]=attrs_):=
    $InterfaceData@"put"[head, "Attributes", attrs];
InterfaceAttributes[head_]:=
  $InterfaceData@"get"[head, "Attributes"];


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceEntryQ*)



iRegisterInterfaceEntryQ[head_, entryQ_]:=
  With[
    {
      checkInvalid=
        If[TrueQ@entryQ,
          System`Private`HoldNotValidQ,
          System`Private`HoldEntryQ
          ],
      checkValid=
        If[TrueQ@entryQ,
          System`Private`HoldValidQ,
          System`Private`HoldNoEntryQ
          ],
      setValid=
        If[TrueQ@entryQ,
          System`Private`HoldSetValid,
          System`Private`HoldSetNoEntry
          ]
      },
    InterfaceCheckInvalid[head]=checkInvalid;
    InterfaceCheckValid[head]=checkValid;
    InterfaceSetValid[head]=setValid;
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceValidator*)



iRegisterInterfaceValidator[
  head_,
  keys_,
  testFunction_
  ]:=
  With[
    {
      checkValid=InterfaceCheckValid[head]
      },
    (* Test if object is object *)
    InterfaceValidator[head]=testFunction;
    testFunction[d_Association?AssociationQ]:=
      AllTrue[keys, KeyExistsQ[d, #]&];
    testFunction/:
      HoldPattern[testFunction[head[a_Association]?checkValid]]:=
      testFunction[a];
    testFunction[___]:=False;
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceConstructor*)



(* ::Text:: *)
(*
	Need to decide whether it\[CloseCurlyQuote]s best to leave unevaluated if the constructor returns an Association or not...
*)



iRegisterInterfaceConstructor[
  head_,
  version_,
  constructor_,
  failureFunction_,
  failOnUndefinedArguments_
  ]:=
  With[
    {
      validator=InterfaceValidator[head],
      checkInvalid=InterfaceCheckInvalid[head],
      setValid=InterfaceSetValid[head]
      },
    InterfaceConstructor[head]=constructor;
    (* Constructor DownValue on the object *)
    Unprotect[head];
    head//ClearAll;
    head~SetAttributes~HoldAllComplete;
    If[Length@DownValues@PackageExceptionBlock>0,
      With[{tag=SymbolName[head]},
        head[args___]?checkInvalid:=
          With[{a=PackageExceptionBlock[tag]@constructor[args]},
            PackageExceptionBlock[tag]@If[AssociationQ@a,
              With[{a2=Append[a, "Version"->version]},
                If[TrueQ@validator@a2,
                  setValid@head[a2],
                  failureFunction[head, args]
                  ]
                ],
              failureFunction[head, args]
              ]/;(TrueQ[failOnUndefinedArguments]||AssociationQ[a])
            ];
        ],
      head[args___]?checkInvalid:=
        With[{a=constructor[args]},
          If[AssociationQ@a,
            With[{a2=Append[a, "Version"->version]},
              If[TrueQ@validator@a2,
                setValid@head[a2],
                failureFunction[head, args]
                ]
              ],
            failureFunction[head, args]
            ]/;(TrueQ[failOnUndefinedArguments]||AssociationQ[a])
          ]
      ];
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceMutationHandler*)



$noArgMutations=
  Alternatives@@
    {Unset, Increment, Decrement};


$oneArgMutations=
  Alternatives@@
    {
        Set, SetDelayed,
        AddTo, SubtractFrom, TimesBy, DivideBy,
        AppendTo, PrependTo,
        AssociateTo, KeyDropFrom
        };


iRegisterInterfaceMutationHandler[
  head_,
  func_,
  dispatcher_
  ]:=
  With[
    {
      oQ=InterfaceValidator[head],
      symQ=Unique[symbolQ],
      oA=$oneArgMutations,
      nA=$noArgMutations,
      d=
        If[!AssociationQ@dispatcher, 
          <|"Keys"->dispatcher|>,
          dispatcher
          ]
      },
    symQ~SetAttributes~{Temporary, HoldFirst};
    symQ[sym_]:=
      MatchQ[OwnValues[sym], {_:>_head?oQ}];
    func // ClearAll;
    func~SetAttributes~HoldAllComplete;
    If[KeyExistsQ[d, "Self"],
      With[{subdispatch=dispatcher["Self"]},
        func[
          (h: oA)[obj_Symbol?symQ, val_]
          ] :=
          With[{res=subdispatch[h][obj, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ]
          ] :=
          With[{res=subdispatch[h][obj]},
            (obj=res)/;Head[res]===head
            ];
        ];
      ];
    If[KeyExistsQ[d, "Keys"],
      With[{subdispatch=dispatcher["Keys"]},
        func[
          (h: oA)[obj_Symbol?symQ[attr__], val_]
          ] :=
          With[{res=subdispatch[h][obj, {attr}, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ[attr__]]
          ] :=
          With[{res=subdispatch[h][obj, {attr}]},
            (obj=res)/;Head[res]===head
            ];
        ]
      ];
    If[KeyExistsQ[d, "Parts"],
      With[{subdispatch=dispatcher["Parts"]},
        func[
          (h: oA)[obj_Symbol?symQ[[part__]], val_]
          ] :=
          With[{res=subdispatch[h][obj, {part}, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ[[part__]]]
          ] :=
          With[{res=subdispatch[h][obj, {part}]},
            (obj=res)/;Head[res]===head
            ];
        ]
      ];
    (* fallthrough to get normal behavior back *)
    func[___] := Language`MutationFallthrough;
    Language`SetMutationHandler[head, func];
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceMutationHandler*)



$noArgMutations=
  Alternatives@@
    {Unset, Increment, Decrement};


$oneArgMutations=
  Alternatives@@
    {
        Set, SetDelayed,
        AddTo, SubtractFrom, TimesBy, DivideBy,
        AppendTo, PrependTo,
        AssociateTo, KeyDropFrom
        };


iRegisterInterfaceMutationHandler[
  head_,
  func_,
  dispatcher_
  ]:=
  With[
    {
      oQ=InterfaceValidator[head],
      symQ=Unique[symbolQ],
      oA=$oneArgMutations,
      nA=$noArgMutations,
      d=
        If[!AssociationQ@dispatcher, 
          <|"Keys"->dispatcher|>,
          dispatcher
          ]
      },
    symQ~SetAttributes~{Temporary, HoldFirst};
    symQ[sym_]:=
      MatchQ[OwnValues[sym], {_:>_head?oQ}];
    func // ClearAll;
    func~SetAttributes~HoldAllComplete;
    If[KeyExistsQ[d, "Self"],
      With[{subdispatch=dispatcher["Self"]},
        func[
          (h: oA)[obj_Symbol?symQ, val_]
          ] :=
          With[{res=subdispatch[h][obj, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ]
          ] :=
          With[{res=subdispatch[h][obj]},
            (obj=res)/;Head[res]===head
            ];
        ];
      ];
    If[KeyExistsQ[d, "Keys"],
      With[{subdispatch=dispatcher["Keys"]},
        func[
          (h: oA)[obj_Symbol?symQ[attr__], val_]
          ] :=
          With[{res=subdispatch[h][obj, {attr}, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ[attr__]]
          ] :=
          With[{res=subdispatch[h][obj, {attr}]},
            (obj=res)/;Head[res]===head
            ];
        ]
      ];
    If[KeyExistsQ[d, "Parts"],
      With[{subdispatch=dispatcher["Parts"]},
        func[
          (h: oA)[obj_Symbol?symQ[[part__]], val_]
          ] :=
          With[{res=subdispatch[h][obj, {part}, val]},
            (obj=res)/;Head[res]===head
            ];
        func[
          (h : nA)[obj_Symbol?symQ[[part__]]]
          ] :=
          With[{res=subdispatch[h][obj, {part}]},
            (obj=res)/;Head[res]===head
            ];
        ]
      ];
    (* fallthrough to get normal behavior back *)
    func[___] := Language`MutationFallthrough;
    Language`SetMutationHandler[head, func];
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceMethod*)



iRegisterInterfaceMethod~SetAttributes~HoldRest;
iRegisterInterfaceMethod[
  head_,
  methodName_,
  lhs_,
  args___,
  def_
  ]:=
  With[
    {
      mn=methodName,
      valid=InterfaceValidator[head],
      meths=InterfaceMethods[head],
      attrs=Attributes[head]
      },
    If[MemberQ[attrs, Protected], Unprotect[head]];
    InterfaceMethods[head]=
      If[meths===Null,
        <|mn->True|>,
        Append[meths, mn->True]
        ]; 
    head/:lhs?valid[mn[args]]:=
      def;
    head/:lhs?valid[mn][args]:=
      def;
    If[MemberQ[attrs, Protected], Protect[head]];
    ];


Unprotect[InterfaceMethod];
InterfaceMethod/:
  (
    InterfaceMethod[head_][
      lhs_[method_][args___]
      ]:=def_
    ):=
    iRegisterInterfaceMethod[head, method, lhs, args, def];
InterfaceMethod/:
  (
    InterfaceMethod[head_][
      lhs_[method_[[args___]]]
      ]:=def_
    ):=
    iRegisterInterfaceMethod[head, method, lhs, args, def];
Protect[InterfaceMethod];


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceAttribute*)



iRegisterInterfaceAttribute~SetAttributes~HoldRest;
iRegisterInterfaceAttribute[
  head_,
  methodName_,
  lhs_,
  def_
  ]:=
  With[
    {
      mn=methodName,
      valid=InterfaceValidator[head],
      meths=InterfaceAttributes[head],
      attrs=Attributes[head]
      },
    If[MemberQ[attrs, Protected], Unprotect[head]];
    InterfaceAttributes[head]=
      If[meths===Null,
        <|mn->True|>,
        Append[meths, mn->True]
        ]; 
    head/:lhs?valid[mn]:=
      def;
    If[MemberQ[attrs, Protected], Protect[head]];
    ];


Unprotect[InterfaceAttribute];
InterfaceAttribute/:
  (
    InterfaceAttribute[head_][
      lhs_[method_]
      ]:=def_
    ):=
    iRegisterInterfaceAttribute[head, method, lhs, def];
Protect[InterfaceAttribute]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceOverride*)



iRegisterInterfaceOverride~SetAttributes~HoldRest;
iRegisterInterfaceOverride[
  head_,
  upval_,
  {lh___},
  main_,
  {rh___},
  def_
  ]:=
  With[
    {
      mn=upval,
      valid=InterfaceValidator[head],
      attrs=Attributes[head]
      },
    If[MemberQ[attrs, Protected], Unprotect[head]];
    head/:upval[lh, main?valid, rh]:=
      def;
    If[MemberQ[attrs, Protected], Protect[head]];
    ];


Unprotect[InterfaceOverride];
InterfaceOverride/:
  (
    InterfaceOverride[head_][
      upval_[args___]
      ]:=def_
    ):=
    Module[
      {
        pivot,
        argList
        },
      argList=Thread[HoldComplete[{args}]];
      pivot=
        SelectFirst[Range[Length[argList]], !FreeQ[argList[[#]], head]&,
         Length[argList]+1];
      argList=
        Map[
          Thread[#, HoldComplete]&, 
          {
            Take[argList, UpTo[pivot-1]], 
            argList[[{pivot}]],
            Drop[argList, UpTo[pivot]]
            }
          ];
      Replace[argList,
        {
          HoldComplete[{lh___}]|{lh___}, 
          HoldComplete[{main_}], 
          HoldComplete[{rh___}]|{rh___}
          }:>
          iRegisterInterfaceOverride[head, upval, {lh}, main, {rh}, def]
        ]
      ];
Protect[InterfaceOverride]


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceAccessor*)



iRegisterInterfaceAccessor[head_, dispatcher_]:=
  With[
    {
      ea=If[!AssociationQ@dispatcher, <|"Keys"->dispatcher|>, dispatcher],
      valid=InterfaceValidator[head]
      },
    If[KeyExistsQ[ea, "Keys"],
      With[{lookup=dispatcher["Keys"]},
        obj_head?valid[attr_String?(
          !KeyExistsQ[
            Join[InterfaceMethods[head], InterfaceAttributes[head]], 
            #
            ]&)]:=
          With[{res=lookup[obj, attr]}, res/;Head[res]=!=lookup];
        obj_head?valid[attr:Except[_String|_String[___]]]:=
          With[{res=lookup[obj, attr]}, res/;Head[res]=!=lookup];
        obj_head?valid[attr1_, attrs__]:=
          With[{res=lookup[obj, attr1, attrs]}, res/;Head[res]=!=lookup];
        ];
      ];
    If[KeyExistsQ[ea, "Parts"],
      With[{part=dispatcher["Parts"]},
        head/:obj_head?valid[[p__]]:=
          With[{res=part[obj, p]},
            res/;Head[res]=!=part
            ];
        ];
      ];
    ];


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceNormalForm*)



iRegisterInterfaceNormalForm[head_, norm_]:=
  With[
    {
      valid=InterfaceValidator[head]
      },
    head/:HoldPattern[Normal[head[a_]?valid]]:=norm@a
    ];


(* ::Subsubsection::Closed:: *)
(*iRegisterInterfaceFormatting*)



iRegisterInterfaceFormatting[
  head_,
  icon_(*,
	keys_ I'll add this in the future...
	*)
  ]:=
  With[{valid=InterfaceValidator[head]},
    Format[
      HoldPattern[
        obj:head[a_]?(Function[Null, valid[Unevaluated[#]], HoldAllComplete])
        ]
      ]:=
      RawBoxes@
        BoxForm`ArrangeSummaryBox[
          head,
          Unevaluated[head@@{a}],
          icon,
          {
            BoxForm`MakeSummaryItem[
              {
                "Keys: ", 
                DeleteCases[Keys@a, "Version"]
                },
              StandardForm
              ]
            },
          {
            },
          StandardForm
          ]
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterDefaultInterfaceAttributes*)



(* ::Subsubsubsection::Closed:: *)
(*Properties*)



registerDefaultAttr[head_, validator_, "Properties"]:=
  (
    InterfaceAttribute[head][HoldPattern[head[a_]]["Properties"]]:=
      Join[
        Keys[a],
        Keys@InterfaceAttributes[head]
        ]
    )


(* ::Subsubsubsection::Closed:: *)
(*Methods*)



registerDefaultAttr[head_, validator_, "Methods"]:=
  (
    InterfaceAttribute[head][HoldPattern[head[a_]]["Methods"]]:=
      Keys@InterfaceMethods[head]
    )


(* ::Subsubsubsection::Closed:: *)
(*iRegisterDefaultInterfaceMethods*)



iRegisterDefaultInterfaceAttributes[head_, attrs_]:=
  With[{v=InterfaceValidator[head]},
    Scan[registerDefaultAttr[head, v, #]&, attrs]
    ]


(* ::Subsubsection::Closed:: *)
(*iRegisterDefaultInterfaceMethods*)



(* ::Subsubsubsection::Closed:: *)
(*Association*)



registerDefaultMethod[head_, validator_, Association]:=
  head/:HoldPattern@Association[head[a_]?validator]:=
    Association[a];


(* ::Subsubsubsection::Closed:: *)
(*Keys*)



registerDefaultMethod[head_, validator_, Keys]:=
  head/:HoldPattern@Keys[head[a_]?validator]:=
    Keys[a];


(* ::Subsubsubsection::Closed:: *)
(*Values*)



registerDefaultMethod[head_, validator_, Values]:=
  head/:HoldPattern@Values[head[a_]?validator]:=
    Values[a];


(* ::Subsubsubsection::Closed:: *)
(*ReplacePart*)



registerDefaultMethod[head_, validator_, ReplacePart]:=
  head/:HoldPattern@ReplacePart[head[a_]?validator, k_]:=
    head[ReplacePart[a, k]]


(* ::Subsubsubsection::Closed:: *)
(*MapAt*)



registerDefaultMethod[head_, validator_, MapAt]:=
  head/:HoldPattern@MapAt[f_, head[a_]?validator, k_]:=
    head[MapAt[f, a, k]]


(* ::Subsubsubsection::Closed:: *)
(*SetProperty*)



registerDefaultMethod[head_, validator_, SetProperty]:=
  head/:HoldPattern@SetProperty[obj:_head?validator, p:_Rule|_RuleDelayed]:=
    InterfaceSetProperty[obj, p]


(* ::Subsubsubsection::Closed:: *)
(*PropertyValue*)



registerDefaultMethod[head_, validator_, PropertyValue]:=
  head/:HoldPattern@PropertyValue[obj:_head?validator, p_]:=
    InterfacePropertyValue[obj, p]


(* ::Subsubsubsection::Closed:: *)
(*RemoveProperty*)



registerDefaultMethod[head_, validator_, RemoveProperty]:=
  head/:HoldPattern@RemoveProperty[obj:_head?validator, p_]:=
    InterfaceRemoveProperty[obj, p]


(* ::Subsubsubsection::Closed:: *)
(*PropertyList*)



registerDefaultMethod[head_, validator_, PropertyList]:=
  head/:HoldPattern@PropertyList[obj:_head?validator]:=
    InterfacePropertyList[obj]


(* ::Subsubsubsection::Closed:: *)
(*iRegisterDefaultInterfaceMethods*)



iRegisterDefaultInterfaceMethods[head_, fns_]:=
  With[{v=InterfaceValidator[head]},
    Scan[registerDefaultMethod[head, v, #]&, fns]
    ]


(* ::Subsection:: *)
(*Modifications*)



(* ::Subsubsection::Closed:: *)
(*InterfaceModify*)



InterfaceModify[
  head_, 
  og:head_[a_], 
  fn_,
  copyProperties_:None
  ]:=
  Module[{new=fn@a},
    If[AssociationQ@new, 
      new=head@a;
      ];
    If[TrueQ@InterfaceValidator[head]@new,
      If[ListQ@copyProperties,
        InterfaceCopyProperties[og, new, copyProperties]
        ];
      new,
      $Failed (* ... maybe this should return some message ? ... *)
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*InterfaceAssociation*)



InterfaceAssociation[head_, head_[a_]]:=
  a;


End[];


EndPackage[];



