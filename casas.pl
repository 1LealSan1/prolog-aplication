% Conectar a la base de datos
conectar_bd :-
    odbc_connect('casas_db', _, [user('user2'), password('123'), alias(casas_db), open(once)]).

% Cerrar la conexiï¿½n a la base de datos
cerrar_bd :-
    odbc_disconnect(casas_db).

% Convertir todas las filas de la tabla 'casas' en hechos de Prolog
casas :-
    odbc_query(casas_db, 'SELECT casas.numero, casas.idsensorIF, casas.idsensorDIST, areas.nombre FROM casas JOIN areas ON casas.idarea = areas.idareas', Row, []),
    assert_casas(Row),
    fail.
casas.

assert_casas(row(Numero, IdSensorIF, IdSensorDIST, NombreArea)) :-
    assertz(casa(Numero, IdSensorIF, IdSensorDIST, NombreArea)).

% Convertir el estado de uso de las casas en hechos de Prolog
status_uso :-
    odbc_query(casas_db, 'SELECT casas.numero, casas.statusUSO FROM casas', Row, []),
    assert_status_uso(Row),
    fail.
status_uso.

assert_status_uso(row(Numero, StatusUso)) :-
    assertz(status_use(Numero, StatusUso)).

% Convertir el terreno de las casas en hechos de Prolog
terrenos :-
    odbc_query(casas_db, 'SELECT casas.numero, casas.terreno FROM casas', Row, []),
    assert_terreno(Row),
    fail.
terrenos.

assert_terreno(row(Numero, Terreno)) :-
    assertz(terreno(Numero, Terreno)).

% Convertir las filas de la tabla 'sensores' en hechos de Prolog
sensores :-
    odbc_query(casas_db, 'SELECT sensores.idsensores, sensores.tiposensor FROM sensores', Row, []),
    assert_sensor(Row),
    fail.
sensores.

assert_sensor(row(IdSensor, TipoSensor)) :-
    assertz(sensor(IdSensor, TipoSensor)).

% Convertir el estado de los sensores en hechos de Prolog
status_sensores :-
    odbc_query(casas_db, 'SELECT sensores.idsensores, sensores.status FROM sensores', Row, []),
    assert_status_sensor(Row),
    fail.
status_sensores.

assert_status_sensor(row(IdSensor, Status)) :-
    assertz(status_sensor(IdSensor, Status)).

% Convertir los logs en hechos de Prolog
logs :-
    odbc_query(casas_db, 'SELECT logs.id_log, logs.id_sensor, logs.distancia, logs.fecha FROM logs', Row, []),
    assert_logs(Row),
    fail.
logs.

assert_logs(row(IdLog, IdSensor, Distancia, Fecha)) :-
    assertz(log(IdLog, IdSensor, Distancia, Fecha)).


% Definir los periodos del dïa
periodo('madrugada', 0, 7).
periodo('dia', 8, 17).
periodo('noche', 18, 23).

% Funcion para generar todos los hechos
generar_hechos :-
    retractall(casa(_, _, _, _)),
    retractall(status_use(_, _)),
    retractall(terreno(_, _)),
    retractall(sensor(_, _)),
    retractall(status_sensor(_, _)),
    retractall(log(_, _, _, _)),
    conectar_bd,
    casas,
    status_uso,
    terrenos,
    sensores,
    status_sensores,
    logs,
    cerrar_bd.

% Imprimir los hechos
imprimir_hechos :-
   % Limpiar los hechos
    generar_hechos,
    write('Hechos de casas:'), nl,
    listing(casa),
    write('Hechos de status de uso:'), nl,
    listing(status_use),
    write('Hechos de terreno:'), nl,
    listing(terreno),
    write('Hechos de sensores:'), nl,
    listing(sensor),
    write('Hechos de status de sensor:'), nl,
    listing(status_sensor),
    write('Hechos de periodos del día:'), nl,
    listing(periodo),
    write('Hechos de logs:'), nl,
    listing(log).

sensor_in_casa(IdSensor) :-
    sensor(IdSensor, _), % Check if IdSensor corresponds to a sensor fact
    (casa(_, IdSensor, _, _); casa(_, _, IdSensor, _)). % Check if IdSensor belongs to a casa

nivel_alerta(LogId, Numero, Area, 'BAJA') :-
    log(LogId, IdSensor, Distancia, timestamp(_, _, _, Hora, _, _, 0)),
    sensor(IdSensor, TipoSensor),
    (TipoSensor = 'infrarrojo'; TipoSensor = 'distancia'),
    casa(Numero, _, IdSensorDist, Area),
    status_use(Numero, StatusUso),
    StatusUso = 1,
    terreno(Numero, Terreno),
    Distancia >= 0.1, Distancia =< 15,
    Distancia =< Terreno,
    periodo(Periodo, HoraInicio, HoraFin),
    Hora >= HoraInicio,
    Hora =< HoraFin,
    Periodo = 'dia',
    not((log(OtroLogId, IdSensorDist, _, _), OtroLogId \= LogId)).

nivel_alerta(LogId, Numero, Area, 'MEDIA') :-
    log(LogId, IdSensor, Distancia, timestamp(_, _, _, Hora, _, _, 0)),
    sensor(IdSensor, TipoSensor),
    (TipoSensor = 'infrarrojo'; TipoSensor = 'distancia'),
    casa(Numero, _, IdSensorDist, Area),
    status_use(Numero, StatusUso),
    terreno(Numero, Terreno),
    Distancia >= 0.1, Distancia =< 15,
    Distancia =< Terreno,
    periodo(Periodo, HoraInicio, HoraFin),
    Hora >= HoraInicio,
    Hora =< HoraFin,
    (Periodo = 'dia', StatusUso = 0; Periodo = 'noche'),
    not((log(OtroLogId, IdSensorDist, _, _), OtroLogId \= LogId)).


nivel_alerta(LogId, Numero, Area, 'ALTA') :-
    log(LogId, IdSensor, Distancia, timestamp(_, _, _, Hora, _, _, 0)),
    sensor(IdSensor, TipoSensor),
    (TipoSensor = 'infrarrojo'; TipoSensor = 'distancia'),
    casa(Numero, _, IdSensorDist, Area),
    status_use(Numero, StatusUso),
    (StatusUso = 0 ; StatusUso = 1),
    terreno(Numero, Terreno),
    Distancia >= 0.1, Distancia =< 15,
    Distancia =< Terreno,
    periodo(Periodo, HoraInicio, HoraFin),
    Hora >= HoraInicio,
    Hora =< HoraFin,
    Periodo = 'madrugada',
    not((log(OtroLogId, IdSensorDist, _, _), OtroLogId \= LogId)).

alerta_recursiva(Alerta) :-
    log(LogId, IdSensor, _, timestamp(Year, Month, Day, Hour, Minute, Second, _)),
    sensor_in_casa(IdSensor),
    casa(Numero, IdSensorIF, IdSensorDIST, Area),
    (IdSensor = IdSensorIF; IdSensor = IdSensorDIST),
    nivel_alerta(LogId, Numero, Area, Alerta),
    format(atom(Message), 'El sensor ~w se ha activado en la casa ~w en el area ~w a las ~w-~w-~w ~w:~w:~w y el nivel de alerta es ~w.', [IdSensor, Numero, Area, Year, Month, Day, Hour, Minute, Second, Alerta]),
    format(atom(Query), 'INSERT INTO alertas (mensaje, nivel_alerta) VALUES (\'~w\', \'~w\')', [Message, Alerta]),
    conectar_bd,
    odbc_query(casas_db, Query),
    cerrar_bd,
    fail.
alerta_recursiva(_).

