// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


pragma solidity ^0.4.24;

import "./Pairing.sol";

library Verifier
{
    using Pairing for Pairing.G1Point;
    using Pairing for Pairing.G2Point;

    struct VerifyingKey
    {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gammaABC;
    }

    struct Proof
    {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    struct ProofWithInput
    {
        Proof proof;
        uint256[] input;
    }

    function Verify (VerifyingKey memory vk, ProofWithInput memory pwi)
        internal returns (bool)
    {
        return Verify(vk, pwi.proof, pwi.input);
    }

    function Verify (VerifyingKey memory vk, Proof memory proof, uint256[] memory input)
        internal returns (bool)
    {
        require(input.length + 1 == vk.gammaABC.length);

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = vk.gammaABC[0];
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.pointAdd(vk_x, Pairing.pointMul(vk.gammaABC[i + 1], input[i]));

        // Verify proof
        return Pairing.pairingProd4(
            proof.A, proof.B,
            vk_x.negate(), vk.gamma,
            proof.C.negate(), vk.delta,
            vk.alpha.negate(), vk.beta);
    }
}