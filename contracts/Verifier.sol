// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verifier {
    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    ECPoint public G1 = ECPoint(1, 2);
    uint256 curve_order =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function ecAdd(
        ECPoint memory p1,
        ECPoint memory p2
    ) public view returns (ECPoint memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-add-failed");
    }

    function ecMul(
        ECPoint memory p,
        uint256 s
    ) public view returns (ECPoint memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    function expmod(uint base, uint e, uint m) public view returns (uint o) {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            // data
            o := mload(p)
        }
    }

    function add(
        ECPoint calldata A,
        ECPoint calldata B,
        uint256 z
    ) public view returns (bool verified) {
        // return true if the prover knows two numbers that add up to num/den
        ECPoint memory proof = ecAdd(A, B);
        ECPoint memory result = ecMul(G1, z);

        verified = proof.x == result.x && proof.y == result.y;
    }

    function rationalAdd(
        ECPoint calldata A,
        ECPoint calldata B,
        uint256 num,
        uint256 dem
    ) public view returns (bool verified) {
        // return true if the prover knows two numbers that add up to num/den
        ECPoint memory proof = ecAdd(A, B);
        uint num_dem = mulmod(
            num,
            expmod(dem, curve_order - 2, curve_order),
            curve_order
        );
        ECPoint memory result = ecMul(G1, num_dem);

        verified = proof.x == result.x && proof.y == result.y;
    }

    function matmul2x2(
        uint256[] calldata matrix, // assume always 2x2
        ECPoint[] calldata s, // n elements
        uint256[] calldata o // n elements
    ) public view returns (bool verified) {
        // return true if the prover knows a matrix M such that M*s = o
        require(matrix.length == 4, "matrix must have 4 elements");
        ECPoint[2] memory proof = [
            ecAdd(ecMul(s[0], matrix[0]), ecMul(s[1], matrix[1])),
            ecAdd(ecMul(s[0], matrix[2]), ecMul(s[1], matrix[3]))
        ];

        ECPoint[2] memory result = [ecMul(G1, o[0]), ecMul(G1, o[1])];

        verified =
            proof[0].x == result[0].x &&
            proof[0].y == result[0].y &&
            proof[1].x == result[1].x &&
            proof[1].y == result[1].y;
    }

    function matmul3x3(
        uint256[] calldata matrix, // assume always 2x2
        ECPoint[] calldata s, // n elements
        uint256[] calldata o // n elements
    ) public view returns (bool verified) {
        // return true if the prover knows a matrix M such that M*s = o
        require(matrix.length == 9, "matrix must be 3x3");
        ECPoint[3] memory proof = [
            ecAdd(
                ecAdd(ecMul(s[0], matrix[0]), ecMul(s[1], matrix[1])),
                ecMul(s[2], matrix[2])
            ),
            ecAdd(
                ecAdd(ecMul(s[0], matrix[3]), ecMul(s[1], matrix[4])),
                ecMul(s[2], matrix[5])
            ),
            ecAdd(
                ecAdd(ecMul(s[0], matrix[6]), ecMul(s[1], matrix[7])),
                ecMul(s[2], matrix[8])
            )
        ];

        ECPoint[3] memory result = [
            ecMul(G1, o[0]),
            ecMul(G1, o[1]),
            ecMul(G1, o[2])
        ];

        verified =
            proof[0].x == result[0].x &&
            proof[0].y == result[0].y &&
            proof[1].x == result[1].x &&
            proof[1].y == result[1].y &&
            proof[2].x == result[2].x &&
            proof[2].y == result[2].y;
    }
}
