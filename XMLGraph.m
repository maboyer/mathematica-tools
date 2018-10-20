(* ::Package:: *)

(* Autogenerated Package *)

BeginPackage["XMLGraph`"];


(* ::Text:: *)
(*
	XMLGraph is an object that is stored as XMLGraph[data] where data is an Association or other object that supports key access mechanisms that stores the core XMLGraph data.
	Keys *must* include \[OpenCurlyDoubleQuote]Graph\[CloseCurlyDoubleQuote], \[OpenCurlyDoubleQuote]Data\[CloseCurlyDoubleQuote],  \[OpenCurlyDoubleQuote]Version\[CloseCurlyDoubleQuote].
		Data      -- data for each node
		Graph   -- structural representation of the XML
		Version -- version of the object API
	Each node in Graph will have an entry in Data. Structural lookups happen on the Graph. Data lookups happen on the data.
*)



XMLGraph::usage=
  "A Graph-based representation of XML data";


BeginPackage["`Package`"];


(* ::Subsubsection::Closed:: *)
(*Node Stuff*)



$NodeDefaults::usage="Defaults for created nodes";
Node::usage="Head for a node";


CreateNode::usage=
  "Creates a node/set of nodes";
InsertNodes::usage=
  "Adds nodes to the graph";
DeleteNodes::usage=
  "Deletes nodes from the graph";
ModifyNodes::usage=
  "Modifies a node or set of nodes on the graph";


RootNode::usage=
  "Gets the XML root element";
NodeList::usage=
  "Lists the nodes on the Graph";
NodeData::usage=
  "Gets a set of nodes off the graph";
SelectNodes::usage=
  "Selects nodes by some criterion";


(* ::Subsubsection::Closed:: *)
(*Object Stuff*)



ConstructXMLGraph::usage="";
XMLGraphQ::usage="Tests whether an XMLGraph structure is a valid XML graph";
MutableXMLGraph::usage="Creates a mutable XMLGraph";
MutableXMLGraphQ::usage="Tests whether a graph is mutable or not";


(* ::Subsubsection::Closed:: *)
(*Conversions*)



FromXMLAssociation::usage="";
ToXMLAssociation::usage="";


FromXMLObject::usage="";
ToXMLObject::usage="";


(* ::Subsubsection::Closed:: *)
(*Graph Operations*)



XMLSubgraph::usage="Extracts a subgraph starting from a head node";
FormattedXMLGraph::usage="Returns the Graph with nice formatting";
XMLGraphSort::usage="Sorts the XMLGraph by distance from the \"Root\" node";


EndPackage[];


Begin["`Private`"];


(* ::Subsection:: *)
(*Object API*)



XMLGraph//Clear


(* ::Subsubsection::Closed:: *)
(*XMLGraphQ*)



(* ::Subsubsubsection::Closed:: *)
(*XMLGraphQ*)



XMLGraphQ[a:Except[_XMLGraph]]:=
  Quiet[TrueQ@KeyExistsQ[a, "Version"]]&&
    AllTrue[{"Graph", "Data"}, KeyExistsQ[a, #]&];
HoldPattern[XMLGraphQ[XMLGraph[a_]?(System`Private`HoldNotValidQ)]]:=
  XMLGraphQ@a
XMLGraphQ[_XMLGraph?(System`Private`HoldValidQ)]:=
  True;
XMLGraphQ[___]:=False


(* ::Subsubsubsection::Closed:: *)
(*MutableXMLGraphQ*)



HoldPattern[MutableXMLGraphQ[XMLGraph[a_]]]:=
  MutableXMLGraphQ@a;
MutableXMLGraphQ[a:Except[_XMLGraph]]:=
  TrueQ@a["Mutable"]


(* ::Subsubsection::Closed:: *)
(*Constructor*)



(* ::Subsubsubsection::Closed:: *)
(*XMLGraph*)



HoldPattern[XMLGraph[a_]?(System`Private`HoldNotValidQ)]:=
  With[{res=ConstructXMLGraph[a]},
    res/;XMLGraphQ[res]
    ];


(* ::Subsubsubsection::Closed:: *)
(*ConstructXMLGraph*)



$XMLGraphDefaults=
  <|
    "Version"->1,
    "Graph"->VertexAdd[Graph[{}], "Root"],
    "Data"-><||>
    |>;


ConstructXMLGraph//Clear;


ConstructXMLGraph[a_Association]:=
  If[Length@a>0&&AssociationQ@a[[1]]&&
    AllTrue[{"Type", "Meta", "Children"}, KeyExistsQ[a[[1]], #]&],
    FromXMLAssociation@a,
    Module[
      {
        assoc=
          Join[
            $XMLGraphDefaults,
            KeyTake[a, {"Version", "Graph", "Data"}]
            ]
        },
      Replace[EdgeList[assoc["Graph"], "Root"\[UndirectedEdge]_],
        el:{"Root"\[UndirectedEdge]n_}:>
          Set[assoc["Graph"], 
            EdgeAdd[EdgeDelete[assoc["Graph"], el], "Root"\[DirectedEdge]n]
            ]
        ];
      With[{d=assoc},
        System`Private`HoldSetValid@XMLGraph[d]
        ]
      ]
    ];
ConstructXMLGraph[xml:_XMLElement|(XMLObject[_][_, _, _])|_String]:=
  FromXMLObject[xml];
ConstructXMLGraph[e_]:=
  With[{a=Association@e},
    If[AssociationQ@a,
      XMLGraph@a,
      If[Quiet@Check[BooleanQ@KeyExistsQ[e, "Version"], False], 
        KeyValueMap[
          If[!KeyExistsQ[e, #],
            e[#]=#2
            ]&,
          $XMLGraphDefaults
          ];
        If[!XMLGraphQ[e], $Failed, 
          Replace[EdgeList[e["Graph"], "Root"\[UndirectedEdge]_],
            el:{"Root"\[UndirectedEdge]n_}:>
              Set[e["Graph"], 
                EdgeAdd[EdgeDelete[e["Graph"], el], "Root"\[DirectedEdge]n]
                ]
            ];
          System`Private`HoldSetValid@XMLGraph[e]
          ],
        $Failed
        ]
      ]
    ]


(* ::Subsubsubsection::Closed:: *)
(*MutableXMLGraph*)



MutableXMLGraph[x_XMLGraph?XMLGraphQ]:=
  If[MutableXMLGraphQ[x], 
    x,
    Quiet@
      Check[
        Get["HashTableInterface`"],
        Get["https://github.com/b3m2a1/mathematica-tools/raw/master/HashTableInterface.m"]
        ];
    Module[{b=HashTableInterface`HashTable[x["Backend"]]},
      b["Mutable"]=True;
      XMLGraph[b]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*Accessor API*)



(* ::Subsubsubsection::Closed:: *)
(*Backend*)



HoldPattern@XMLGraph[a_]["Backend"]:=
  a


(* ::Subsubsubsection::Closed:: *)
(*Graph*)



HoldPattern@XMLGraph[a_]["Graph"]:=
  a["Graph"]


(* ::Subsubsubsection::Closed:: *)
(*Data*)



HoldPattern@XMLGraph[a_]["Data"]:=
  a["Data"]


(* ::Subsubsection::Closed:: *)
(*Format*)



Format[x_XMLGraph?XMLGraphQ]:=
  RawBoxes@
    With[
      {
        g=VertexCount@x["Graph"]-1,
        r=Replace[RootNode[x], s:Except[None]:>x["Data"][s, "Type"]]
        },
      BoxForm`ArrangeSummaryBox[
        XMLGraph,
        x,
        None,
        {
          BoxForm`MakeSummaryItem[{"Root: ", r}, StandardForm],
          BoxForm`MakeSummaryItem[{"Nodes: ", g}, StandardForm]
          },
        {},
        StandardForm
        ]
      ]


(* ::Subsubsection::Closed:: *)
(*Attributes*)



(* ::Subsubsubsection::Closed:: *)
(*Insert*)



x_XMLGraph?XMLGraphQ["Insert"[n_]]:=
  InsertNodes[x, n]


(* ::Subsubsubsection::Closed:: *)
(*Delete*)



x_XMLGraph?XMLGraphQ["Delete"[n_]]:=
  DeleteNodes[x, n]


(* ::Subsubsubsection::Closed:: *)
(*Modify*)



x_XMLGraph?XMLGraphQ["ModifyNodes"[n_]]:=
  ModifyNodes[x, n]


(* ::Subsubsubsection::Closed:: *)
(*FormattedGraph*)



x_XMLGraph?XMLGraphQ["FormattedGraph"[o___]]:=
  FormattedXMLGraph[x, o];


(* ::Subsubsubsection::Closed:: *)
(*Nodes*)



x_XMLGraph?XMLGraphQ["Nodes"]:=
  NodeList[x]


(* ::Subsubsubsection::Closed:: *)
(*Select*)



x_XMLGraph?XMLGraphQ["Select"[fn_, n___]]:=
  SelectNodes[x, fn, n]


(* ::Subsubsubsection::Closed:: *)
(*Data*)



x_XMLGraph?XMLGraphQ["Data"[n__]]:=
  NodeData[x, n]


(* ::Subsubsubsection::Closed:: *)
(*Meta*)



x_XMLGraph?XMLGraphQ["Meta"[n_]]:=
  NodeData[x, n, "Meta"]


(* ::Subsubsubsection::Closed:: *)
(*Children*)



x_XMLGraph?XMLGraphQ["Children"[n_]]:=
  NodeData[x, n, "Children"]


(* ::Subsubsubsection::Closed:: *)
(*Sort*)



x_XMLGraph?XMLGraphQ["Sort"[]]:=
  XMLGraphSort[x]


(* ::Subsubsubsection::Closed:: *)
(*Subgraph*)



x_XMLGraph?XMLGraphQ["Subgraph"[k_]]:=
  XMLSubgraph[x, k]


(* ::Subsubsubsection::Closed:: *)
(*XML*)



x_XMLGraph?XMLGraphQ["XML"]:=
  ToXMLObject[x]


(* ::Subsubsubsection::Closed:: *)
(*Association*)



x_XMLGraph?XMLGraphQ["Association"]:=
  ToXMLAssociation[x]


(* ::Subsection:: *)
(*Node API*)



(* ::Subsubsection::Closed:: *)
(*$NodeDefaults*)



$NodeDefaults=
  <|
    "Type"->"p",
    "Meta"-><||>,
    "Children"->{}
    |>


(* ::Subsubsection::Closed:: *)
(*ValidateNode*)



(* ::Text:: *)
(*...I should probably write this...*)



(* ::Subsubsection::Closed:: *)
(*Node*)



With[
  {
    baseBoxes=
    RawBoxes@
      BoxForm`ArrangeSummaryBox[
        Node,
        Node[$$name],
        None,
        {$$name},
        {},
        StandardForm
        ]/.DynamicModuleBox[_, b_, ___]:>
              RuleCondition[b/.PaneSelectorBox[s_, ___]:>Lookup[s, False], True]
    },
  Format[Node[name_String]]:=
    baseBoxes/.{
      $$name->name,
      TagBox["$$name", "SummaryItem"]:>
      RuleCondition[TagBox[ToString[name, InputForm], "SummaryItem"], True]
      }
  ]


(* ::Subsubsection::Closed:: *)
(*CreateNode*)



(* ::Text:: *)
(*
	CreateNode takes a parent node and a list of child-specs and creates an Association for the children out of it.
	Returns {{childData}, {nodeSpecs...}} where each nodeSpec is an Association and the childData is data about the children of the parent node.
*)



(* ::Subsubsubsection::Closed:: *)
(*CreateNode*)



CreateNode[d_]:=
  Reap[createNode[d]];


(* ::Subsubsubsection::Closed:: *)
(*createNode*)



createNode[parent_->XMLElement[d_, c_, b_]]:=
  createNode[
    parent->
      <|"Type"->d, "Meta"->c, "Children"->b|>
    ];
createNode[parent_->kid_Association]:=
  Module[
    {
      data=<|"Parent"->parent|>,
      children
      },
    data["Type"]=Lookup[kid, "Type", $NodeDefaults["Type"]];
    data["Name"]=CreateUUID[data["Type"]<>":"];
    data["Meta"]=Lookup[kid, "Meta", $NodeDefaults["Meta"]];
    data["Children"]=
      createNode[
        data["Name"]->
          Flatten@List@Lookup[kid, "Children", $NodeDefaults["Children"]]
        ];
    Sow[data];
    Node[data["Name"]]
    ]
createNode[parent_->kids:l_List]:=
  createNode/@Thread[parent->kids];
createNode[parent_->kid_]:=
  kid


(* ::Subsubsection::Closed:: *)
(*InsertNodes*)



InsertNodes[
  x_XMLGraph?XMLGraphQ, 
  nodes:{__Rule}
  ]:=
  Module[
    {
      a=XMLGraph["Backend"],
      data,
      parents=Keys@nodes,
      pos,
      nodez=Values@nodes,
      children,
      others,
      edges,
      new
      },
    (* If no position is specifed insert at the end *)
    parents=
      If[!ListQ@#, {#, -1}, #]&/@parents;
    {parents, pos}=Transpose@parents;
    (* Create new nodes from rules *)
    nodez=Flatten[{#}, 1]&/@nodez;
    nodez=CreateNode/@Thread[parents->nodez];
    new=Join@@nodez[[All, 2]];
    (* Add constructed edges to the Graph *)
    edges=
      Map[#["Parent"]->#["Name"]&, new];
    a["Graph"]=
      EdgeAdd[a["Graph"],
        UndirectedEdge@@@edges
        ];
    (* Add data to Data association *)
    data=a["Data"];
    MapThread[
      Function[
        data[#, "Children"]=
          FlattenAt[
            Insert[data[#, "Children"], #3, #2],
            #2
            ];
        data[#, "Children"]
        ],
      {
        parents,
        pos,
        nodez[[All, 1]]
        }
      ];
    Map[Function[data[#["Name"]]=#], new];
    (* Return new XMLGraph and added nodes *)
    {If[MutableXMLGraphQ@x, x, XMLGraph@a], edges[[All, 2]]}
    ]


(* ::Subsubsection::Closed:: *)
(*DeleteNodes*)



DeleteNodes[
  x_XMLGraph,
  n:{__String}
  ]:=
  Module[
    {
      a=x["Backend"],
      g,
      d,
      vs
      },
    g=a["Graph"];
    g=VertexDelete[g, n];
    a["Graph"]=g;
    d=a["Data"];
    vs=Lookup[d, n];
    a["Data"]=KeyDrop[d, n];
    {If[MutableXMLGraphQ@x, x, XMLGraph@a], vs}
    ]


(* ::Subsubsection::Closed:: *)
(*ModifyNodes*)



ModifyNodes[
  x_XMLGraph,
  n:{__Rule}
  ]:=
  Module[
    {
      a=x["Backend"],
      g,
      d,
      vs=Keys@n,
      ms=Association/@Values[n]
      },
    d=a["Data"];
    MapThread[
      Function[
        d[#, "Type"]=
          Lookup[#2, "Type", d[#, "Type"]];
        d[#, "Meta"]=
          Merge[{d[#, "Meta"], KeyDrop[#2, "Type"]}, Last];
        ],
      {
        vs,
        ms
        }
      ];
    a["Data"]=d;
    If[MutableXMLGraphQ@x, x, XMLGraph@a]
    ]


(* ::Subsubsection::Closed:: *)
(*RootNode*)



RootNode[x_XMLGraph]:=
  If[Length@#>0, 
    #[[1, 2]],
    None
    ]&@IncidenceList[x["Graph"], "Root"]


(* ::Subsubsection::Closed:: *)
(*NodeList*)



NodeList[x_XMLGraph]:=
  Keys@x["Data"]


(* ::Subsubsection::Closed:: *)
(*SelectNodes*)



SelectNodes[x_XMLGraph, test_String]:=
  Keys@Select[x["Data"][[All, "Type"]], #==test&];
SelectNodes[x_XMLGraph, test:Except[_String]]:=
  Keys@Select[x["Data"], test];
SelectNodes[x_XMLGraph, test_String, n_]:=
  Keys@Select[x["Data"][[All, "Type"]], #==test&, n];
SelectNodes[x_XMLGraph, test:Except[_String], n_]:=
  Keys@Select[x["Data"], test, n];


(* ::Subsubsection::Closed:: *)
(*NodeData*)



NodeData[x_XMLGraph, n_String, Optional[All, All]]:=
  x["Data"][n];
NodeData[x_XMLGraph, n_String, part:_String|{__String}]:=
  x["Data"][[n, part]];
NodeData[x_XMLGraph, n:{__String}, parts:_String|{__String}|All:All]:=
  Lookup[x["Data"], n][[All, parts]];
NodeData[x_XMLGraph, i:_Integer|{__Integer}|_Span, parts:_String|{__String}|All:All]:=
  NodeData[x, VertexList[x["Graph"]][[i]]]


(* ::Subsection:: *)
(*Graph API*)



(* ::Subsubsection::Closed:: *)
(*XMLSubgraph*)



xmlNodeTree[d_, n_]:=
  {
    n,
    Cases[
      d[n, "Children"], 
      Node[s_]:>xmlNodeFullChildren[d, s]
      ]
    };
xmlNodeTree~SetAttributes~HoldFirst;


xmlSubtree[g_, d_, n_]:=
  SelectFirst[
    ConnectedComponents[VertexDelete[g, d[n, "Parent"]]],
    MemberQ[n]
    ];


XMLSubgraph[x_XMLGraph, node_]:=
  Module[
    {
      verts,
      sa,
      sg,
      g=x["Graph"],
      d=x["Data"]
      },
    verts=xmlSubtree[g, d, node];
    XMLGraph@
      <|
        "Data"->AssociationThread[verts, Lookup[d, verts]],
        "Graph"->EdgeAdd[Subgraph[g, verts], "Root"->node]
        |>
    ]


(* ::Subsubsection::Closed:: *)
(*FormattedXMLGraph*)



Options[FormattedXMLGraph]=
  Join[
    Options[Graph], 
    {
      ColorRules->
        {
          "Root"->Black,
          "body"->ColorData[97][1],
          "head"->ColorData[97][2],
          "div"->ColorData[97][3],
          "p"->ColorData[97][4]
          }
      }
    ];  
FormattedXMLGraph[x_XMLGraph, ops:OptionsPattern[]]:=
  Module[
    {
      g=(*VertexDelete[#, "Root"]&@*)x["Graph"],
      a=x["Data"],
      r=RootNode[x],
      cr=OptionValue[ColorRules],
      vs
      },
    cr=
      Dispatch@Flatten@{cr/."Root"->r, _->None};
    vs=
      Normal@DeleteCases[None]@
        AssociationMap[
          Replace[#["Type"], cr]&, 
          VertexList@g
          ];
    Graph[
      g,
      VertexStyle->vs,
      GraphLayout->"LayeredEmbedding",
      ops
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*XMLGraphSort*)



XMLGraphSort[x_XMLGraph]:=
  Module[
    {
      a=x["Backend"],
      graph,
      vl,
      vo
      },
    graph=a["Graph"];
    vl=VertexList@graph;
    vo=Ordering@GraphDistance[graph, "Root"];
    a["Graph"]=Graph[VertexList[a][[vo]], EdgeList[a]];
    If[MutableGraphQ@x, x, XMLGraph[a]]
    ]


(* ::Subsection:: *)
(*Conversion API*)



(* ::Subsubsection::Closed:: *)
(*FromXMLAssociation*)



(* ::Subsubsubsection::Closed:: *)
(*fromAssoc*)



fromAssoc[p_, a_]:=
  With[{name=Lookup[a, "Name", CreateUUID[a["Type"]<>":"]]},
    Sow@
      Join[
        <|
          "Parent"->p,
          "Name"->name
          |>,
        MapAt[a,
          Replace[#, 
            b_Association?AssociationQ:>
              With[{ba=fromAssoc[name, b]},
                Node[ba["Name"]]
                ]
            ]&,
          "Children"
          ]
        ];
    ]


(* ::Subsubsubsection::Closed:: *)
(*FromXMLAssociation*)



FromXMLAssociation[a_Association]:=
  Module[
    {
      data=Flatten[Reap[fromAssoc["Root", a]][[2]], 1]
      },
    ConstructXMLGraph@
      <|
        "Data"->AssociationThread[Lookup[data, "Name"], data],
        "Graph"->Thread[UndirectedEdge[Lookup[data, "Parent"], Lookup[data, "Name"]]]
        |>
    ]


(* ::Subsubsection::Closed:: *)
(*ToXMLAssociation*)



(* ::Subsubsubsection::Closed:: *)
(*BFS*)



(* ::Text:: *)
(*
	I think a recursive algorithm will actually perform better
*)



(*insertAssociationVertex[Hold[d_, a_, p_]][node_, parent_, depth_]:=
	(
		p[node]={p[parent], parent};
		a[Sequence@@Flatten@{p[node], node}]=d[a];
		a[Sequence@@Flatten@{p[node]}]=
		)*)


(*ToXMLAssociation[x_XMLGraph]:=
	Module[
		{
			a=<||>,
			p=<||>,
			d=x["Data"],
			r=RootNode[x]
			},
		p[r]={};
		BreadthFirstScan[x["Graph"],
			r,
			{
				"DiscoverVertex"->
					insertAssociationVertex[Hold[d, a, p]]
				}
			];
		a
		]*)


(* ::Subsubsubsection::Closed:: *)
(*Recursive*)



toXMLAssociationRec[d_, n_]:=
  MapAt[
    Replace[#, Node[s_]:>toXMLAssociationRec[d, s], 1]&,
    d[n],
    "Children"
    ];
toXMLAssociationRec~SetAttributes~HoldFirst


ToXMLAssociation[x_XMLGraph]:=
  Module[
    {
      d=x["Data"],
      r=RootNode[x]
      },
    toXMLAssociationRec[d, r]
    ]


(* ::Subsubsection::Closed:: *)
(*FromXMLObject*)



FromXMLObject[s_String]:=
  FromXMLObject@
    Quiet@Check[ImportString[s, "XML"], ImportString[s, {"HTML", "XMLObject"}]];
FromXMLObject[XMLObject[_][_, d_, _]]:=
  FromXMLObject[d];
FromXMLObject[x_XMLElement]:=
  Module[
    {
      nodes=CreateNode["Root"->x],
      edges,
      graph,
      data
      },
    nodes=Flatten[nodes[[2]], 1];
    data=AssociationThread[Lookup[nodes, "Name"], nodes];
    edges=
      Thread@
        UndirectedEdge[Lookup[nodes, "Parent"], Lookup[nodes, "Name"]];
    graph=TreeGraph[edges];
    ConstructXMLGraph@
      <|
        "Graph"->graph,
        "Data"->data
        |>
    ]


(* ::Subsubsection::Closed:: *)
(*ToXMLObject*)



toXMLElementRec[d_, n_]:=
  Module[{a=d[n]},
    XMLElement[
      a["Type"],
      a["Meta"],
      Replace[a["Children"], Node[s_]:>toXMLElementRec[d, s], 1]
      ]
    ];
toXMLElementRec~SetAttributes~HoldFirst


ToXMLObject[x_XMLGraph]:=
  Module[
    {
      d=x["Data"],
      r=RootNode[x]
      },
    toXMLElementRec[d, r]
    ]


End[];


EndPackage[];



