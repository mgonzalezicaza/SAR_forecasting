*===============================*
* MATA PROGRAMS         *
*===============================*

// SK 14 June 2010 // very bad choice of program names: st_* are the Mata functions
//                    to interface with Stata. Use capitals or something.
//                    Some Mata functions use magic Stata matrix return names; should
//                    use string scalar names as parameters
// SK 21 June 2010 // matrix J is easily mixed with Mata J() function, especially
//                    when it is subscripted

* Modified by: Kelly Y. Montoya - Jul 19/2022 Added st_corr2 to correct error on st_corr function. 

* Creates a matrix with quantity of employees by sector
* name1 = matrix with growth rates by sector
* name2 = matrix with baseline of employment by sector
* c = colum of reference where the data of employment is within name2 matrix
* n = number of sectors in the economy

capture mata : mata drop st_mat()
capture mata : mata drop st_order()
capture mata : mata drop st_repond()
capture mata : mata drop st_repond_1()
capture mata : mata drop st_dif()
capture mata : mata drop st_corr()
capture mata : mata drop st_corr2()
capture mata : mata drop st_transf()
capture mata : mata drop st_gr()

mata:
void st_mat(string scalar name1, string scalar name2, real scalar c, real scalar n)
{
    real matrix M, V, B
    M = st_matrix(name1)
    M = M[1..n,c] + J(n,1,1)
    V = st_matrix(name2)
    V = V[1..n,c]
    N = V:/colsum(V)
    B = M:*V
    J = M:*N
    J = N,J
    st_matrix("sector_mata", B)
    st_matrix("shares_mata", J)
}
end

* Order sectors
* 4 arguments:  1 - matrix's name we want to order
*       2 - column we want to keep from the original matrix
*       3 - column and order sign of the new matrix
*       4 - name of the output matrix to stata
mata:
void st_order(string scalar name1, real scalar n, real scalar c, string scalar name2)
{
    real matrix V
    real colvector i

    V = st_matrix(name1)
    i = 1::rows(V)
    V = i,V[1..rows(V),n]
    V = sort(V,c)
    st_matrix(name2,V)
}
end

* Repondera los valores de una columna y calcula en forma opcional las proporciones
* 4 argumentos: 1 - nombre de la matriz que se desea reponderar
*       2 - columna a extraer de la matriz original
*       3 - total de la poblacion final
*       4 - nombre de la matriz de salida a stata
*       5 - opcion para el calculo de las participaciones por sector


mata:
void st_repond(string scalar name1, string scalar name2, real scalar n, real scalar c, string scalar name3, | string scalar name4)
{
    real matrix V, G
    real rowvector t
    real colvector i

    V = st_matrix(name1)
    V = V[1..rows(V),n]
    t = round(colsum(V))
    V = V[1..rows(V),1]:*c/t[1..1,1]
    st_matrix(name3,V)

    if (args()==6)  {
        i = 1::rows(V)
        G = st_matrix(name2)
        G = G[1..rows(G),c]
        V = i,V,G
        V = select(V[.,1..2],V[.,3]:>0)
        t = colsum(V[.,2])
        V = V[.,1], V[.,2]:*c/t[1..1,1]
        st_matrix(name4,V)
        }
    }
// SK 21 June 2010 // name4 never used
end


mata:
void st_repond_1(string scalar name1, string scalar name2, real scalar n, real scalar c, string scalar name3, | string scalar name4)
{
    real matrix V, G
    real rowvector t
    real colvector i

    V = st_matrix(name1)
    V = V[1..rows(V),n]
    t = colsum(V)
    V = V[1..rows(V),1]:*c/t[1..1,1]
    st_matrix(name3,V)

    if (args()==6)  {
        i = 1::rows(V)
        G = st_matrix(name2)
        G = G[1..rows(G),c]
        V = i,V,G
        V = select(V[.,1..2],V[.,3]:>0)
        t = colsum(V[.,2])
        V = V[.,1], V[.,2]:*c/t[1..1,1]
        st_matrix(name4,V)
        }
    }
// SK 21 June 2010 // name4 never used
end




mata:
void st_dif(string scalar name1, string scalar name2)
{
    real matrix M, V, D

    M = st_matrix(name1)
    V = st_matrix(name2)
    D = ((V:/M):-1):*100
    st_matrix("diff", D)
}
end

// SK 21 June 2010 // this program generated an error today, all of a sudden
//                    check with earlier versions of this program and its caller, 16*.do
mata:
void st_corr(string scalar name1, string scalar name2, string scalar name3)
{
    real scalar M, C;
    real matrix G, H, V;

    M = st_numscalar(name1)
    C = st_numscalar(name2)
    V = st_matrix(name3)
    G = M*(1 + V)
    H = (G/C)-1
    st_matrix("growth_inla_n",H)
}
end

* KM: This is the new function, but it esencially follows the previous one correcting element "V".
mata:
void st_corr2(string scalar name1, string scalar name2, string scalar name3)
{
    real scalar M, C;
    real matrix G, H, V;

    M = st_numscalar(name1)
    C = st_numscalar(name2)
    V = st_numscalar(name3)
    G = M*(1 + V)
    H = (G/C)-1
    st_matrix("growth_inla_n",H)
}
end


mata:
void st_transf(string scalar name1, string scalar name2, string scalar name3, string scalar name4, string scalar name5)
{
    t   = st_numscalar(name1)
    Med = st_matrix(name2)
    Me  = st_matrix(name3)
    R   = st_matrix(name4)
    Th  = st_matrix(name5)
    A1  = R:*Me
    A   = A1[(1..(rows(A1)-1)),(1..2)]:/A1[rows(A1),cols(A1)]
    T   = A:*t
    X   = T:/Me[(1..(rows(A1)-1)),(1..2)]
    J   = X:/Th[(1..(rows(A1)-1)),(1..2)]
    K   = X:/R[(1..(rows(A1)-1)),(1..2)]

    // SK 21 June 2010 // should code 1 or 2 for the column number
    st_matrix("SH_r", J[(1..(rows(A1)-1)),(1..1)])
    st_matrix("SH_u", J[(1..(rows(A1)-1)),(2..2)])
    st_matrix("tr_r", Me[(1..(rows(A1)-1)),(1..1)])
    st_matrix("tr_u", Me[(1..(rows(A1)-1)),(2..2)])
    st_matrix("N_r", Th[(1..(rows(A1)-1)),(1..1)])
    st_matrix("N_u", Th[(1..(rows(A1)-1)),(2..2)])

    st_matrix("sh_r", K[(1..(rows(A1)-1)),(1..1)])
    st_matrix("sh_u", K[(1..(rows(A1)-1)),(2..2)])
    st_matrix("n_r", R[(1..(rows(A1)-1)),(1..1)])
    st_matrix("n_u", R[(1..(rows(A1)-1)),(2..2)])


}
end


mata:
void st_gr(string scalar name1, string scalar name2)
{
    real matrix M, J, K

    M = st_matrix(name1)
    K = st_matrix(name2)
    J = M:/colsum(M)
    L = (K[1..rows(K),2]:/J) - J(rows(K),1,1)
    st_matrix("growth_estru_n",L)
}
end
