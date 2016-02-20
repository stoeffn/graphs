unit app;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids, Spin,
  StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    btn_tree: TButton;
    input: TSpinEdit;
    grid: TStringGrid;

    procedure btn_treeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure gridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    procedure inputChange(Sender: TObject);

    procedure refreshGrid;
  private
  private
    { private declarations }
  public
    { public declarations }
  end;

  TEdge = record
    first: Integer;
    second: Integer;
  end;

  TVertexState = (Unset=0, Unconnected=1, Connected=2);
  TAdjacencyMatrix = array of array of TVertexState;
  TVertexList = array of Integer;
  TEdgeList = array of TEdge;

var
  Form1: TForm1;
  adjacencyMatrix: TAdjacencyMatrix;

implementation


{ Set all vertexes in matrix given to unconnected }
procedure clearMatrix(var matrix: TAdjacencyMatrix);
var
  x, y: Integer;
begin
  //loop through matrix and set each value to unconnected
  for x := 0 to length(matrix) - 1 do
    for y := 0 to length(matrix[x]) - 1 do
      matrix[x, y] := Unconnected;
end;

{ Fill matrix given by settings all unset vertexes to unconnected }
procedure fillMatrix(var matrix: TAdjacencyMatrix);
var
  x, y: Integer;
begin
  //loop through matrix and set each value to unconnected if it was not set before
  for x := 0 to length(matrix) - 1 do
    for y := 0 to length(matrix[x]) - 1 do
      if matrix[x, y] = Unset then
        matrix[x, y] := Unconnected;
end;

{ Add edges to matrix given }
procedure applyEdgesToMatrix(var matrix: TAdjacencyMatrix; edges: TEdgeList);
var
  i: Integer;
begin
  //loop through edges and set both directions for adjacency matrix as connected
  for i := 0 to length(edges) - 1 do
  begin
    matrix[edges[i].first][edges[i].second] := Connected;
    matrix[edges[i].second][edges[i].first] := Connected;
  end;
end;

{ Test wether a certain vertex is contained in list for vertexes given }
function isVertexInList(vertex: Integer; vertexList: TVertexList): Boolean;
var
  i: Integer;
begin
  //loop through list of vertexes
  for i := 0 to length(vertexList) - 1 do
    //early return true if current vertex equals vertex given
    if vertexList[i] = vertex then
    begin
      result := True;
      exit;
    end;

  result := False;
end;

{ Get next neighbour node of vertex given

  Return first neighbour vertex for given vertex that is not in the
  to-be-exluded list. If no neighbour was found, return -1.
}
function getNextNeighbourVertex(matrix: TAdjacencyMatrix; vertex: Integer;
  exludeVertexes: TVertexList): Integer;
var
  y: Integer;
begin
  //loop through adjacency matrix column for vertex given
  for y := 0 to length(matrix[vertex]) - 1 do
    //early return vertex if is connected and not in to-be-excluded list
    if (matrix[vertex, y] = Connected) and (not isVertexInList(y, exludeVertexes)) then
    begin
      result := y;
      exit;
    end;

  result := -1;
end;

{ Perform breadth-first search on adjacency matrix given

  Return list of edges being a spanning tree.
}
function breadthFirstSearch(matrix: TAdjacencyMatrix): TEdgeList;
var
  currentVertex, nextNeighbourVertex: Integer;
  activeVertexes, processedVertexes: TVertexList;
  currentEdge: TEdge;
  edges: TEdgeList;
begin
  //initialize active and processed vertexes list with first vertex
  setLength(activeVertexes, 1);
  activeVertexes[0] := 0;
  setLength(processedVertexes, 1);
  processedVertexes[0] := 0;

  //repeat until all active nodes' neighbours are processed
  while length(activeVertexes) <> 0 do
  begin
    //get first vertex from active vertex and its next neighbour
    currentVertex := activeVertexes[0];
    nextNeighbourVertex := getNextNeighbourVertex(matrix, currentVertex, processedVertexes);

    //test wether a neighbour was found
    if nextNeighbourVertex = -1 then
    begin
      //remove first vertex from active vertexes list
      Move(activeVertexes[1], activeVertexes[0], SizeOf(activeVertexes[0]) * (Length(activeVertexes) - 1));
      SetLength(activeVertexes, Length(activeVertexes) - 1);
    end
    else
    begin
      //add neighbour vertex to active and proccessed neighbor list
      setLength(activeVertexes, length(activeVertexes) + 1);
      activeVertexes[length(activeVertexes) - 1] := nextNeighbourVertex;
      setLength(processedVertexes, length(processedVertexes) + 1);
      processedVertexes[length(processedVertexes) - 1] := nextNeighbourVertex;

      //add edge from currently active to neighbour vertex
      currentEdge.first := currentVertex;
      currentEdge.second := nextNeighbourVertex;
      setLength(edges, length(edges) + 1);
      edges[length(edges) -1] := currentEdge;
    end;
  end;

  result := edges;
end;


{$R *.lfm}

{ executed on form creation }
procedure TForm1.FormCreate(Sender: TObject);
begin
  //emulate change of adjacency matrix's size for initialization
  inputChange(Sender);
end;

{ Handle cell selection in grid }
procedure TForm1.gridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  //make sure a valid position was selected
  if (aCol > 0) and (aRow > 0) then
  begin
    //change vertex state based on its current state
    if adjacencyMatrix[aCol - 1, aRow - 1] = Connected then
      adjacencyMatrix[aCol - 1, aRow - 1] := Unconnected
    else
      adjacencyMatrix[aCol - 1, aRow - 1] := Connected;

    refreshGrid;
    CanSelect := True;
  end
  else
    CanSelect := False;
end;

{ Handle change of matrix size input value }
procedure TForm1.inputChange(Sender: TObject);
var
  i: Integer;
begin
  //adapt size of grid
  grid.RowCount := input.Value + 1;
  grid.ColCount := input.Value + 1;

  //adapt size of matrix
  setLength(adjacencyMatrix, input.Value);

  for i := 0 to length(adjacencyMatrix) - 1 do
    setLength(adjacencyMatrix[i], input.Value);

  //fill new values and refresh UI
  fillMatrix(adjacencyMatrix);
  refreshGrid;
end;

{ Perform breadth-first serach on adjacency matrix }
procedure TForm1.btn_treeClick(Sender: TObject);
var edges: TEdgeList;
begin
  edges := breadthFirstSearch(adjacencyMatrix);

  //reset current matrix, add edges, and resfresh UI
  clearMatrix(adjacencyMatrix);
  applyEdgesToMatrix(adjacencyMatrix, edges);
  refreshGrid;
end;

{ Refresh grid UI from adjacency matrix }
procedure TForm1.refreshGrid;
var
  x, y: Integer;
begin
  //loop through matrix
  for x := 0 to length(adjacencyMatrix) - 1 do
    for y := 0 to length(adjacencyMatrix[x]) - 1 do
      // make sure coordinates are inside bounds of grid
      if (x < grid.ColCount - 1) and (y < grid.RowCount - 1) then
        //display '0' for unconnected and '1' for connected vertexes
        if adjacencyMatrix[x, y] = Unconnected then
          grid.Cells[x + 1, y + 1] := '0'
        else
          grid.Cells[x + 1, y + 1] := '1';
end;

end.
