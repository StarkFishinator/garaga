%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import PoseidonBuiltin
from starkware.cairo.common.registers import get_fp_and_pc
from src.bn254.fq import BigInt3

from src.bn254.towers.e12 import E12, e12, E12D
from src.bn254.towers.e6 import E6, e6
from src.bn254.towers.e2 import E2, e2
from src.bn254.g1 import G1Point, g1
from src.bn254.g2 import G2Point, g2
from starkware.cairo.common.alloc import alloc

from src.bn254.pairing import pair, pair_multi, final_exponentiation
@external
func __setup__() {
    %{
        import subprocess
        import random
        import functools
        import re
        from starkware.cairo.common.cairo_secp.secp_utils import split

        P=0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        BN254_ORDER = 21888242871839275222246405745257275088548364400416034343698204186575808495617
        def rgetattr(obj, attr, *args):
            def _getattr(obj, attr):
                return getattr(obj, attr, *args)
            return functools.reduce(_getattr, [obj] + attr.split('.'))

        def rsetattr(obj, attr, val):
            pre, _, post = attr.rpartition('.')
            return setattr(rgetattr(obj, pre) if pre else obj, post, val)

        def fill_g1_point(g1:str, a0:int, a1:int):
            sa0 = split(a0)
            sa1 = split(a1)

            for i in range(3): rsetattr(ids,g1+'.x.d'+str(i),sa0[i])
            for i in range(3): rsetattr(ids,g1+'.y.d'+str(i),sa1[i])

            return None
        def fill_g2_point(g2:str, a0:int, a1:int, a2, a3):
            sa0 = split(a0)
            sa1 = split(a1)
            sa2 = split(a2)
            sa3 = split(a3)

            for i in range(3): rsetattr(ids,g2+'.x.a0.d'+str(i),sa0[i])
            for i in range(3): rsetattr(ids,g2+'.x.a1.d'+str(i),sa1[i])
            for i in range(3): rsetattr(ids,g2+'.y.a0.d'+str(i),sa2[i])
            for i in range(3): rsetattr(ids,g2+'.y.a1.d'+str(i),sa3[i])

            return None
        def fill_e12(e2:str, *args):
            for i in range(12):
                splitted = split(args[i])
                for j in range(3):
                    rsetattr(ids,e2+str(i)+'.d'+str(j),splitted[j])
            return None
        def fill_element(element:str, value:int):
            s = split(value)
            for i in range(3): rsetattr(ids,element+'.d'+str(i),s[i])
        def parse_fp_elements(input_string:str):
            pattern = re.compile(r'\[([^\[\]]+)\]')
            substrings = pattern.findall(input_string)
            sublists = [substring.split(' ') for substring in substrings]
            sublists = [[int(x) for x in sublist] for sublist in sublists]
            fp_elements = [x[0] + x[1]*2**64 + x[2]*2**128 + x[3]*2**192 for x in sublists]
            return fp_elements
    %}
    return ();
}

// @external
// func test_final_exp{
//     syscall_ptr: felt*,
//     range_check_ptr,
//     bitwise_ptr: BitwiseBuiltin*,
//     poseidon_ptr: PoseidonBuiltin*,
// }() {
//     alloc_locals;
//     __setup__();
//     let (__fp__, _) = get_fp_and_pc();
//     local x0: BigInt3;
//     local x1: BigInt3;
//     local x2: BigInt3;
//     local x3: BigInt3;
//     local x4: BigInt3;
//     local x5: BigInt3;
//     local x6: BigInt3;
//     local x7: BigInt3;
//     local x8: BigInt3;
//     local x9: BigInt3;
//     local x10: BigInt3;
//     local x11: BigInt3;

// local z0: BigInt3;
//     local z1: BigInt3;
//     local z2: BigInt3;
//     local z3: BigInt3;
//     local z4: BigInt3;
//     local z5: BigInt3;
//     local z6: BigInt3;
//     local z7: BigInt3;
//     local z8: BigInt3;
//     local z9: BigInt3;
//     local z10: BigInt3;
//     local z11: BigInt3;
//     tempvar x = new E12(
//         new E6(new E2(&x0, &x1), new E2(&x2, &x3), new E2(&x4, &x5)),
//         new E6(new E2(&x6, &x7), new E2(&x8, &x9), new E2(&x10, &x11)),
//     );
//     tempvar z = new E12(
//         new E6(new E2(&z0, &z1), new E2(&z2, &z3), new E2(&z4, &z5)),
//         new E6(new E2(&z6, &z7), new E2(&z8, &z9), new E2(&z10, &z11)),
//     );

// %{
//         cmd = ['./tools/gnark/main', 'nG1nG2', '1', '1']
//         out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//         fp_elements_0 = parse_fp_elements(out)
//         assert len(fp_elements_0) == 6

// cmd = ['./tools/gnark/main', 'pair', 'miller_loop'] + [str(x) for x in fp_elements_0]
//         out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//         fp_elements = parse_fp_elements(out)
//         assert len(fp_elements) == 12
//         fill_e12('x', *fp_elements)

// cmd = ['./tools/gnark/main', 'pair', 'pair'] + [str(x) for x in fp_elements_0]
//         out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//         fp_elements = parse_fp_elements(out)
//         assert len(fp_elements) == 12
//         fill_e12('z', *fp_elements)
//     %}

// let res = final_exponentiation(x, 1);

// e12.assert_E12(res, z);
//     return ();
// }

// @external
// func test_pair_gen{
//     syscall_ptr: felt*,
//     range_check_ptr,
//     bitwise_ptr: BitwiseBuiltin*,
//     poseidon_ptr: PoseidonBuiltin*,
// }() {
//     alloc_locals;
//     __setup__();
//     let (__fp__, _) = get_fp_and_pc();

// local g1x: BigInt3;
//     local g1y: BigInt3;

// local g2x0: BigInt3;
//     local g2x1: BigInt3;
//     local g2y0: BigInt3;
//     local g2y1: BigInt3;

// local z0: BigInt3;
//     local z1: BigInt3;
//     local z2: BigInt3;
//     local z3: BigInt3;
//     local z4: BigInt3;
//     local z5: BigInt3;
//     local z6: BigInt3;
//     local z7: BigInt3;
//     local z8: BigInt3;
//     local z9: BigInt3;
//     local z10: BigInt3;
//     local z11: BigInt3;

// %{
//         cmd = ['./tools/gnark/main', 'nG1nG2', '1', '1']
//         out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//         fp_elements = parse_fp_elements(out)
//         assert len(fp_elements) == 6

// fill_element('g1x', fp_elements[0])
//         fill_element('g1y', fp_elements[1])
//         fill_element('g2x0', fp_elements[2])
//         fill_element('g2x1', fp_elements[3])
//         fill_element('g2y0', fp_elements[4])
//         fill_element('g2y1', fp_elements[5])

// cmd = ['./tools/gnark/main', 'pair', 'pair'] + [str(x) for x in fp_elements]
//         out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//         fp_elements_2 = parse_fp_elements(out)
//         assert len(fp_elements_2) == 12

// fill_e12('z', *fp_elements_2)
//     %}
//     local x: G1Point* = new G1Point(&g1x, &g1y);
//     local y: G2Point* = new G2Point(new E2(&g2x0, &g2x1), new E2(&g2y0, &g2y1));
//     local z: E12 = E12(
//         new E6(new E2(&z0, &z1), new E2(&z2, &z3), new E2(&z4, &z5)),
//         new E6(new E2(&z6, &z7), new E2(&z8, &z9), new E2(&z10, &z11)),
//     );
//     g1.assert_on_curve(x);
//     g2.assert_on_curve(y);
//     let res = pair(x, y);

// e12.assert_E12(res, &z);
//     return ();
// }

@external
func test_neg_g1_g2{
    syscall_ptr: felt*,
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    poseidon_ptr: PoseidonBuiltin*,
}() {
    alloc_locals;
    __setup__();
    let (__fp__, _) = get_fp_and_pc();

    local g1x: BigInt3;
    local g1y: BigInt3;

    local g2x0: BigInt3;
    local g2x1: BigInt3;
    local g2y0: BigInt3;
    local g2y1: BigInt3;

    local z0: BigInt3;
    local z1: BigInt3;
    local z2: BigInt3;
    local z3: BigInt3;
    local z4: BigInt3;
    local z5: BigInt3;
    local z6: BigInt3;
    local z7: BigInt3;
    local z8: BigInt3;
    local z9: BigInt3;
    local z10: BigInt3;
    local z11: BigInt3;

    %{
        cmd = ['./tools/gnark/main', 'nG1nG2', '1', '1']
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 6

        fill_element('g1x', fp_elements[0])
        fill_element('g1y', fp_elements[1])
        fill_element('g2x0', fp_elements[2])
        fill_element('g2x1', fp_elements[3])
        fill_element('g2y0', fp_elements[4])
        fill_element('g2y1', fp_elements[5])

        cmd = ['./tools/gnark/main', 'pair', 'pair'] + [str(x) for x in fp_elements]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements_2 = parse_fp_elements(out)
        assert len(fp_elements_2) == 12

        fill_e12('z', *fp_elements_2)
    %}
    local x: G1Point = G1Point(g1x, g1y);
    local yx: E2 = E2(g2x0, g2x1);
    local yy: E2 = E2(g2y0, g2y1);

    local y: G2Point = G2Point(&yx, &yy);

    local z: E12D = E12D(z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10, z11);

    let (local g1_neg) = g1.neg(x);

    let (P_arr: G1Point**) = alloc();
    let (Q_arr: G2Point**) = alloc();
    assert P_arr[0] = &x;
    assert Q_arr[0] = &y;
    assert P_arr[1] = &g1_neg;
    assert Q_arr[1] = &y;

    let ee = pair_multi(P_arr, Q_arr, 2);
    let one = e12.one_full();
    e12.assert_E12D(ee, one);
    return ();
}

// @external
// func test_g1_neg_g2{
//     syscall_ptr: felt*,
//     range_check_ptr,
//     bitwise_ptr: BitwiseBuiltin*,
//     poseidon_ptr: PoseidonBuiltin*,
// }() {
//     alloc_locals;
//     __setup__();
//     let (__fp__, _) = get_fp_and_pc();

// local g1x: BigInt3;
//     local g1y: BigInt3;

// local g2x0: BigInt3;
//     local g2x1: BigInt3;
//     local g2y0: BigInt3;
//     local g2y1: BigInt3;

// local z0: BigInt3;
//     local z1: BigInt3;
//     local z2: BigInt3;
//     local z3: BigInt3;
//     local z4: BigInt3;
//     local z5: BigInt3;
//     local z6: BigInt3;
//     local z7: BigInt3;
//     local z8: BigInt3;
//     local z9: BigInt3;
//     local z10: BigInt3;
//     local z11: BigInt3;

// %{
//                 cmd = ['./tools/gnark/main', 'nG1nG2', '1', '1']
//                 out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//                 fp_elements = parse_fp_elements(out)
//                 assert len(fp_elements) == 6

// fill_element('g1x', fp_elements[0])
//                 fill_element('g1y', fp_elements[1])
//                 fill_element('g2x0', fp_elements[2])
//                 fill_element('g2x1', fp_elements[3])
//                 fill_element('g2y0', fp_elements[4])
//                 fill_element('g2y1', fp_elements[5])

// cmd = ['./tools/gnark/main', 'pair', 'pair'] + [str(x) for x in fp_elements]
//                 out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
//                 fp_elements_2 = parse_fp_elements(out)
//                 assert len(fp_elements_2) == 12

// fill_e12('z', *fp_elements_2)
//     %}
//     local x: G1Point = G1Point(g1x, g1y);
//     local yx: E2 = E2(g2x0, g2x1);
//     local yy: E2 = E2(g2y0, g2y1);
//     local y: G2Point = G2Point(&yx, &yy);

// local z: E12D = E12D(z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10, z11);

// let g2_neg = g2.neg(y);

// let (P_arr: G1Point**) = alloc();
//     let (Q_arr: G2Point**) = alloc();
//     assert P_arr[0] = x;
//     assert Q_arr[0] = y;
//     assert P_arr[1] = x;
//     assert Q_arr[1] = g2_neg;
//     let ee = pair_multi(P_arr, Q_arr, 2);
//     let one = e12.one();
//     e12.assert_E12(ee, one);
//     return ();
// }

@external
func test_pair_random{
    syscall_ptr: felt*,
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    poseidon_ptr: PoseidonBuiltin*,
}() {
    alloc_locals;
    __setup__();
    let (__fp__, _) = get_fp_and_pc();

    local g1x: BigInt3;
    local g1y: BigInt3;

    local g2x0: BigInt3;
    local g2x1: BigInt3;
    local g2y0: BigInt3;
    local g2y1: BigInt3;

    local z0: BigInt3;
    local z1: BigInt3;
    local z2: BigInt3;
    local z3: BigInt3;
    local z4: BigInt3;
    local z5: BigInt3;
    local z6: BigInt3;
    local z7: BigInt3;
    local z8: BigInt3;
    local z9: BigInt3;
    local z10: BigInt3;
    local z11: BigInt3;

    %{
        from tools.py.extension_trick import gnark_to_w
        inputs=[random.randint(0, BN254_ORDER) for i in range(2)]
        cmd = ['./tools/gnark/main', 'nG1nG2']+[str(x) for x in inputs]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 6
        fill_element('g1x', fp_elements[0])
        fill_element('g1y', fp_elements[1])
        fill_element('g2x0', fp_elements[2])
        fill_element('g2x1', fp_elements[3])
        fill_element('g2y0', fp_elements[4])
        fill_element('g2y1', fp_elements[5])

        cmd = ['./tools/gnark/main', 'pair', 'pair'] + [str(x) for x in fp_elements]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 12

        fill_e12('z',*gnark_to_w(fp_elements))
    %}
    local x: G1Point = G1Point(g1x, g1y);
    local yx: E2 = E2(g2x0, g2x1);
    local yy: E2 = E2(g2y0, g2y1);

    local y: G2Point = G2Point(&yx, &yy);
    local z: E12D = E12D(z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10, z11);
    g1.assert_on_curve(&x);
    g2.assert_on_curve(&y);
    let res = pair(x, y);

    e12.assert_E12D(res, &z);
    return ();
}
