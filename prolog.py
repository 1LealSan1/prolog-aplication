from pyswip import Prolog

prolog = Prolog()

prolog.consult('casas.pl')

# Call your Prolog rule
results = list(prolog.query('imprimir_hechos'))

  # Print the results
for result in results:
    print(result) 

# Call your Prolog rule
results = list(prolog.query('alerta_recursiva(Alerta)'))

  # Print the results
for result in results:
    print(result) 