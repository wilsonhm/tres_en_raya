import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tres en Raya',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Resultado> resultados = [];
  bool gameStarted = false;
  List<List<String>> board = List.generate(3, (_) => List.filled(3, ''));
  String jugador1 = '';
  String jugador2 = '';
  bool isPlayer1Turn = true;
  String currentPlayer = 'X';
  String winner = '';
  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  String turnoActual = '';
  TextEditingController jugador1Controller = TextEditingController();
  TextEditingController jugador2Controller = TextEditingController();
  int currentPage = 1;
  int itemsPerPage = 10;
  @override
  void dispose() {
    jugador1Controller.dispose();
    jugador2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isBoardFull() {
  for (int row = 0; row < board.length; row++) {
    for (int col = 0; col < board[row].length; col++) {
      if (board[row][col].isEmpty) {
        return false;
      }
    }
  }

  return true;
}
    return Scaffold(
      appBar: AppBar(
        title: Text('Tres en Raya'),
      ),
      body: SingleChildScrollView(
         child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!gameStarted)
              Column(
                children: [
                  TextField(
                    controller: jugador1Controller,
                    decoration: InputDecoration(
                      labelText: 'Nombre Jugador 1',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: jugador2Controller,
                    decoration: InputDecoration(
                      labelText: 'Nombre Jugador 2',
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
           
           Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: !gameStarted ? startGame : null,
                  child: Text('Iniciar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: gameStarted ? cancelGame : null,
                  child: Text('Anular'),
                ),
              ],
            ),
            SizedBox(height: 10),
        
            if (gameStarted)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(
                
                'Jugador 1: $jugador1',
                style: TextStyle(fontSize: 16),
              ),
               SizedBox(width: 20),
              Text(
                'Jugador 2: $jugador2',
                style: TextStyle(fontSize: 16),
              ),
               ],
              ),
              SizedBox(height: 20),
            Text(
              'Turno: $turnoActual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),


            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              itemCount: 9,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ 3;
                final col = index % 3;
                return ElevatedButton(
                  onPressed: gameStarted && board[row][col].isEmpty
                      ? () => makeMove(row, col)
                      : null,
                  child: Text(board[row][col]),
                );
              },
            ),  
            SizedBox(height: 20),
            if (winner.isNotEmpty)
              Text('¡Ganador: $winner!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
             if (isBoardFull() && winner.isEmpty)
              Text(
                '¡Empate!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
               SizedBox(height: 20),
           Text(
                'Tabla de Puntajes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<Resultado>>(
                future: databaseHelper.getResults(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final results = snapshot.data!;
                    
                    return DataTable(
                      columns: [
                        DataColumn(label: Text('Jugador 1')),
                        DataColumn(label: Text('Jugador 2')),
                        DataColumn(label: Text('Ganador')),
                        DataColumn(label: Text('Puntos')),
                      ],
                      rows: results.map((result) {
                        return DataRow(cells: [
                          DataCell(Text(result.nombreJugador1)),
                          DataCell(Text(result.nombreJugador2)),
                          DataCell(Text(result.ganador)),
                          DataCell(Text(result.punto.toString())),
                        ]);
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error al cargar los puntajes');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
                 ),
          ] ,
        ),
      ),
      ),
    );
  }


  void startGame() async {
    setState(() {
      gameStarted = true;
      jugador1 = jugador1Controller.text;
      jugador2 = jugador2Controller.text;
    });

    Resultado resultado = Resultado(
      nombrePartida: 'Tres en Raya',
      nombreJugador1: 'Jugador 1',
      nombreJugador2: 'Jugador 2',
      ganador: '',
      punto: 0,
      estado: 'J',
    );
    int insertedId = await databaseHelper.insertResult(resultado);
    resultado.id = insertedId;

    List<Resultado> results = await databaseHelper.getResults();
    results.forEach((result) => print(result.toMap()));
    List<Resultado> playingResults = results.where((result) => result.estado == 'J').toList();
  playingResults.forEach((playingResult) => print(playingResult.toMap()));
  }

  void makeMove(int row, int col) {
    if (board[row][col].isEmpty && winner.isEmpty) {
      setState(() {
        board[row][col] = currentPlayer;
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
        checkWinner();
      });
    }
  }

  void checkWinner() {
    // Verificar filas
    for (int i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0].isNotEmpty) {
        setState(() {
          winner = board[i][0];
        });
        break;
      }
    }

    // Verificar columnas
    for (int i = 0; i < 3; i++) {
      if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i].isNotEmpty) {
        setState(() {
          winner = board[0][i];
        });
        break;
      }
    }

    // Verificar diagonales
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0].isNotEmpty) {
      setState(() {
        winner = board[0][0];
      });
    } else if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2].isNotEmpty) {
      setState(() {
        winner = board[0][2];
      });
    }

    if (winner.isNotEmpty) {
      Resultado resultado = Resultado(
        id: 1, // ID de la partida guardada en la base de datos
        nombrePartida: 'Tres en Raya',
        nombreJugador1: 'Jugador 1',
        nombreJugador2: 'Jugador 2',
        ganador: winner,
        punto: 1,
        estado: 'G',
      );
      databaseHelper.updateResult(resultado);
    }
  }

  void cancelGame() {
    setState(() {
      gameStarted = false;
      board = List.generate(3, (_) => List.filled(3, ''));
      currentPlayer = 'X';
      winner = '';
      isPlayer1Turn = true;
      jugador1Controller.clear();
      jugador2Controller.clear();
    });

    Resultado resultado = Resultado(
      id: 1, // ID de la partida guardada en la base de datos
      nombrePartida: 'Tres en Raya',
      nombreJugador1: 'Jugador 1',
      nombreJugador2: 'Jugador 2',
      ganador: '',
      punto: 0,
      estado: 'A',
    );
    databaseHelper.updateResult(resultado);
  }
}
