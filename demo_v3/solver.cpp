/* -------------------------------------------------------------------------
 * MPSiS 2018/2019, L1
 * An example application solving an LP problem defined in an external GMPL file
 * A. Kamisiński
 *
 * Build:
 *  g++ program.cpp -o program_2 -lClp -lCoinUtils
 * -------------------------------------------------------------------------
*/

#include <stdio.h>
#include <coin/ClpSimplex.hpp>
#include <coin/CoinUtilsConfig.h>

int main( int argc, char *argv[] )
{
	ClpSimplex model;
	int status;

	if ( argc < 2 )
	{
		printf( "Usage: ./solve_gmpl <gmpl-model-file> [ <gmpl-data-file> ]\n" );

		return 1;
	}

	if ( argc == 2 )
	{
		status = model.readGMPL( argv[ 1 ], NULL );
	}
	else
	{
		status = model.readGMPL( argv[ 1 ], argv[ 2 ] );
	}
	
	if ( status != 0 )
	{
		printf( "E: Failed to load the model and data files\n" );
		
		return 1;
	}
	
	model.setLogLevel( 0 );
	status = model.primal();
	printf( "----------------------------------------\n" );

	int iterations_count = model.numberIterations();
	printf( "Model status after %d iterations: %d (0: optimal, 1: primal infeasible, 2: dual infeasible, 3: stopped on iterations, 4: stopped due to errors)\n", iterations_count, status );

	if ( model.primalFeasible() == false )
	{
		printf( "PRIMAL INFEASIBLE!\n" );
		
		return 0;
	}
	
	printf( "PRIMAL FEASIBLE! Objective value = %g\n", model.objectiveValue() );

	int rows_count = model.numberRows();
	int columns_count = model.numberColumns();
	
	printf( "The model has %d rows and %d columns.\n", rows_count, columns_count );
	
	double *column_primal = model.primalColumnSolution();
	int i;
/*
Czesc zmieniona, aby czytelniej wyswietlac wyniki. Wyniki czytane od gory do dolu.
*/
	printf("\nThe resulting sequence of results distribution:\n");
	

	FILE *f = fopen("file.txt", "w");
	if (f == NULL)
	{
	    printf("Error opening file!\n");
	    exit(1);
	}
	fprintf(f, "-1;%g\n", model.objectiveValue() );
	for ( i = 0; i < columns_count; i++ )
	{
		printf( "x[%d] = %g\n", i + 1, column_primal[ i ] );
		fprintf(f, "%d;%g\n", i + 1, column_primal[ i ] );
	}
	fclose(f);
	printf("\n");
	double *row_primal = model.primalRowSolution();
	for ( i = rows_count; i > 0; i-- )
	{
		printf( "x[%d] = %g\n", rows_count - i + 1, row_primal[ i - 1 ] );
	}
	return 0;
}

