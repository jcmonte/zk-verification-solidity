import pytest
from ape import project
from py_ecc.bn128 import G1, add, multiply, curve_order

# SETUP PHASE
# NOTE: More on fixtures is discussed in later sections of this guide!
@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def v(owner, project):
    return owner.deploy(project.Verifier)

def p2t(p): # convert big point to string typle
    return (str(p[0]), str(p[1]))

def test_add():
    assert 1 + 1 == 2

def test_modexp(v):
    assert v.expmod(2, 3, 3) == 2

def test_ecAdd(v):
    assert v.ecAdd((1, 2), (1, 2)) == add(G1, G1)

def test_ecMul(v):
    assert v.ecMul((1, 2), 2) == multiply(G1, 2)

def test_add(v):
    assert v.add((1, 2), (1, 2), 2)

def test_rationalAdd(v):
    n = curve_order
    two_thirds = (2 * pow(3, -1, n)) % n # conversion to finite field element
    one_twelfth = (1 * pow(12, -1, n)) % n # conversion to finite field element
    A = multiply(G1, two_thirds)
    B = multiply(G1, one_twelfth)
    assert v.rationalAdd(p2t(A), p2t(B), 3, 4)

def test_matmul2x2(v):
    matrix = [1, 1, 1, 1] # 2x2 matrix
    s = [(1, 2), (1, 2)] # G1 points
    o = [2, 2] # scalars for o

    proof = [add(multiply(G1, matrix[0]), multiply(G1, matrix[1])), add(multiply(G1, matrix[2]), multiply(G1, matrix[3]))]
    res = [multiply(G1, o[0]), multiply(G1, o[1])]
    assert proof == res

    assert v.matmul2x2(matrix, s, o)

def test_matmul3x3(v):
    matrix = [1, 1, 1,  1, 1, 1,  1, 1, 1] # 3x3 matrix
    s = [(1, 2), (1, 2), (1, 2)] # G1 points
    o = [3, 3, 3] # scalars for o

    assert v.matmul3x3(matrix, s, o)