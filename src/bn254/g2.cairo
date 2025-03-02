from src.bn254.towers.e2 import e2, E2

from starkware.cairo.common.cairo_secp.bigint import (
    BigInt3,
    UnreducedBigInt3,
    nondet_bigint3,
    UnreducedBigInt5,
    bigint_mul,
    bigint_to_uint256,
    uint256_to_bigint,
)

from src.bn254.fq import fq_bigint3, is_zero, verify_zero5, assert_reduced_felt, reduce_3, reduce_5
from src.bn254.curve import N_LIMBS, DEGREE, BASE, P0, P1, P2
from src.bn254.g1 import G1Point
from starkware.cairo.common.registers import get_fp_and_pc
from src.bn254.towers.e12 import E12full034

struct G2Point {
    x: E2*,
    y: E2*,
}

struct E4 {
    r0: E2*,
    r1: E2*,
}
namespace g2 {
    func assert_on_curve{range_check_ptr}(pt: G2Point*) -> () {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        assert_reduced_felt(pt.x.a0);
        assert_reduced_felt(pt.x.a1);
        assert_reduced_felt(pt.y.a0);
        assert_reduced_felt(pt.y.a1);

        let left = e2.mul(pt.y, pt.y);
        let x_sq = e2.square(pt.x);
        let x_cube = e2.mul(x_sq, pt.x);
        local b20: BigInt3*;
        local b21: BigInt3*;
        %{
            from starkware.cairo.common.cairo_secp.secp_utils import split
            ids.b20 = segments.gen_arg(split(19485874751759354771024239261021720505790618469301721065564631296452457478373))
            ids.b21 = segments.gen_arg(split(266929791119991161246907387137283842545076965332900288569378510910307636690))
        %}
        local b2: E2 = E2([b20], [b21]);
        let right = e2.add(x_cube, &b2);

        e2.assert_E2(left, right);
        return ();
    }
    func neg{range_check_ptr}(pt: G2Point*) -> G2Point* {
        alloc_locals;
        let x = pt.x;
        let y = e2.neg(pt.y);
        tempvar res = new G2Point(x, y);
        return res;
    }
    func compute_doubling_slope{range_check_ptr}(pt: G2Point*) -> E2* {
        // Returns the slope of the elliptic curve at the given point.
        // The slope is used to compute pt + pt.
        // Assumption: pt != 0.
        // Note that y cannot be zero: assume that it is, then pt = -pt, so 2 * pt = 0, which
        // contradicts the fact that the size of the curve is odd.
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        local slope_a0: BigInt3;
        local slope_a1: BigInt3;
        %{
            from src.hints.fq import bigint_pack, bigint_fill
            from src.hints.e2 import E2
            assert 1 < ids.N_LIMBS <= 12
            p = get_p(ids)
            x = E2(bigint_pack(ids.pt.x.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt.x.a1, ids.N_LIMBS, ids.BASE), p)
            y = E2(bigint_pack(ids.pt.y.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt.y.a1, ids.N_LIMBS, ids.BASE), p)
            value = (3 * x * x) / (2 * y)
            bigint_fill(value.a0, ids.slope_a0, ids.N_LIMBS, ids.BASE)
            bigint_fill(value.a1, ids.slope_a1, ids.N_LIMBS, ids.BASE)
        %}
        assert_reduced_felt(slope_a0);
        assert_reduced_felt(slope_a1);

        let x0_x1: UnreducedBigInt5 = bigint_mul(pt.x.a0, pt.x.a1);
        let x0_sqr: UnreducedBigInt5 = bigint_mul(pt.x.a0, pt.x.a0);
        let x1_sqr: UnreducedBigInt5 = bigint_mul(pt.x.a1, pt.x.a1);

        let s0_y0: UnreducedBigInt5 = bigint_mul(slope_a0, pt.y.a0);
        let s1_y1: UnreducedBigInt5 = bigint_mul(slope_a1, pt.y.a1);

        let s0_y1: UnreducedBigInt5 = bigint_mul(slope_a0, pt.y.a1);
        let s1_y0: UnreducedBigInt5 = bigint_mul(slope_a1, pt.y.a0);

        tempvar TWO = 2;
        tempvar THREE = 3;
        // Verify real
        verify_zero5(
            UnreducedBigInt5(
                d0=THREE * (x0_sqr.d0 - x1_sqr.d0) - TWO * (s0_y0.d0 - s1_y1.d0),
                d1=THREE * (x0_sqr.d1 - x1_sqr.d1) - TWO * (s0_y0.d1 - s1_y1.d1),
                d2=THREE * (x0_sqr.d2 - x1_sqr.d2) - TWO * (s0_y0.d2 - s1_y1.d2),
                d3=THREE * (x0_sqr.d3 - x1_sqr.d3) - TWO * (s0_y0.d3 - s1_y1.d3),
                d4=THREE * (x0_sqr.d4 - x1_sqr.d4) - TWO * (s0_y0.d4 - s1_y1.d4),
            ),
        );
        // Verify imaginary
        verify_zero5(
            UnreducedBigInt5(
                d0=TWO * (THREE * x0_x1.d0 - s0_y1.d0 - s1_y0.d0),
                d1=TWO * (THREE * x0_x1.d1 - s0_y1.d1 - s1_y0.d1),
                d2=TWO * (THREE * x0_x1.d2 - s0_y1.d2 - s1_y0.d2),
                d3=TWO * (THREE * x0_x1.d3 - s0_y1.d3 - s1_y0.d3),
                d4=TWO * (THREE * x0_x1.d4 - s0_y1.d4 - s1_y0.d4),
            ),
        );

        local slope: E2 = E2(a0=slope_a0, a1=slope_a1);

        return &slope;
    }
    // Returns the slope of the line connecting the two given points.
    // The slope is used to compute pt0 + pt1.
    // Assumption: pt0.x != pt1.x (mod field prime).
    func compute_slope{range_check_ptr}(pt0: G2Point*, pt1: G2Point*) -> E2* {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        local slope_a0: BigInt3;
        local slope_a1: BigInt3;
        %{
            from src.hints.fq import bigint_pack, bigint_fill
            from src.hints.e2 import E2
            assert 1 < ids.N_LIMBS <= 12
            assert ids.DEGREE == ids.N_LIMBS-1
            p = get_p(ids)
            x0 = E2(bigint_pack(ids.pt0.x.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt0.x.a1, ids.N_LIMBS, ids.BASE), p)
            y0 = E2(bigint_pack(ids.pt0.y.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt0.y.a1, ids.N_LIMBS, ids.BASE), p)
            x1 = E2(bigint_pack(ids.pt1.x.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt1.x.a1, ids.N_LIMBS, ids.BASE), p)
            y1 = E2(bigint_pack(ids.pt1.y.a0, ids.N_LIMBS, ids.BASE), bigint_pack(ids.pt1.y.a1, ids.N_LIMBS, ids.BASE), p)

            value = (y0 - y1) / (x0 - x1)

            bigint_fill(value.a0, ids.slope_a0, ids.N_LIMBS, ids.BASE)
            bigint_fill(value.a1, ids.slope_a1, ids.N_LIMBS, ids.BASE)
        %}
        assert_reduced_felt(slope_a0);
        assert_reduced_felt(slope_a1);

        tempvar x_diff_real: BigInt3 = BigInt3(
            d0=pt0.x.a0.d0 - pt1.x.a0.d0, d1=pt0.x.a0.d1 - pt1.x.a0.d1, d2=pt0.x.a0.d2 - pt1.x.a0.d2
        );
        tempvar x_diff_imag: BigInt3 = BigInt3(
            d0=pt0.x.a1.d0 - pt1.x.a1.d0, d1=pt0.x.a1.d1 - pt1.x.a1.d1, d2=pt0.x.a1.d2 - pt1.x.a1.d2
        );

        let x_diff_slope_imag_first_term: UnreducedBigInt5 = bigint_mul(x_diff_real, slope_a1);
        let x_diff_slope_imag_second_term: UnreducedBigInt5 = bigint_mul(x_diff_imag, slope_a0);

        let x_diff_real_first_term: UnreducedBigInt5 = bigint_mul(x_diff_real, slope_a0);
        let x_diff_real_second_term: UnreducedBigInt5 = bigint_mul(x_diff_imag, slope_a1);

        verify_zero5(
            UnreducedBigInt5(
                d0=x_diff_slope_imag_first_term.d0 + x_diff_slope_imag_second_term.d0 -
                pt0.y.a1.d0 + pt1.y.a1.d0,
                d1=x_diff_slope_imag_first_term.d1 + x_diff_slope_imag_second_term.d1 -
                pt0.y.a1.d1 + pt1.y.a1.d1,
                d2=x_diff_slope_imag_first_term.d2 + x_diff_slope_imag_second_term.d2 -
                pt0.y.a1.d2 + pt1.y.a1.d2,
                d3=x_diff_slope_imag_first_term.d3 + x_diff_slope_imag_second_term.d3,
                d4=x_diff_slope_imag_first_term.d4 + x_diff_slope_imag_second_term.d4,
            ),
        );

        verify_zero5(
            UnreducedBigInt5(
                d0=x_diff_real_first_term.d0 - x_diff_real_second_term.d0 - pt0.y.a0.d0 +
                pt1.y.a0.d0,
                d1=x_diff_real_first_term.d1 - x_diff_real_second_term.d1 - pt0.y.a0.d1 +
                pt1.y.a0.d1,
                d2=x_diff_real_first_term.d2 - x_diff_real_second_term.d2 - pt0.y.a0.d2 +
                pt1.y.a0.d2,
                d3=x_diff_real_first_term.d3 - x_diff_real_second_term.d3,
                d4=x_diff_real_first_term.d4 - x_diff_real_second_term.d4,
            ),
        );
        local slope: E2 = E2(a0=slope_a0, a1=slope_a1);

        return &slope;
    }

    // DoubleStep doubles a point in affine coordinates, and evaluates the line in Miller loop
    // https://eprint.iacr.org/2013/722.pdf (Section 4.3)
    func double_step{range_check_ptr}(pt: G2Point*) -> (res: G2Point*, line_eval: E12full034*) {
        alloc_locals;

        let (__fp__, _) = get_fp_and_pc();
        // assert_on_curve(pt);
        // precomputations in p :

        // let xp_bar = fq_bigint3.neg(p.x);
        // let yp_prime = fq_bigint3.inv(p.y);
        // let xp_prime = fq_bigint3.mul(xp_bar, yp_prime);
        // paper algo:
        // let two_y = e2.double(pt.y);
        // let A = e2.inv(two_y);
        // let x_sq = e2.square(pt.x);
        // tempvar three = new BigInt3(3, 0, 0);
        // let B = e2.mul_by_element(three, x_sq);
        // let C = e2.mul(A, B);  // lamba : slope
        let C = compute_doubling_slope(pt);

        // let D = e2.double(pt.x);
        // let nx = e2.square(C);
        // let nx = e2.sub(nx, D);

        let nx = e2.square_min_double(C, pt.x);
        // let E = e2.mul(C, pt.x);
        // let E = e2.sub(E, pt.y);
        let E = e2.mul_sub(C, pt.x, pt.y);

        // let ny = e2.mul(C, nx);
        // let ny = e2.sub(E, ny);

        let ny = e2.sub_mul(E, C, nx);

        // assert_on_curve(res);

        // let F = e2.mul_by_element(xp_prime, C);
        // let G = e2.mul_by_element(yp_prime, E);
        local res: G2Point = G2Point(nx, ny);
        // local line_eval: E4 = E4(C, E);
        tempvar nine = 9;
        local line_eval034: E12full034 = E12full034(
            w1=BigInt3(
                C.a0.d0 - nine * C.a1.d0, C.a0.d1 - nine * C.a1.d1, C.a0.d2 - nine * C.a1.d2
            ),
            w3=BigInt3(
                E.a0.d0 - nine * E.a1.d0, E.a0.d1 - nine * E.a1.d1, E.a0.d2 - nine * E.a1.d2
            ),
            w7=C.a1,
            w9=E.a1,
        );

        return (&res, &line_eval034);
    }
    func add_step{range_check_ptr}(pt0: G2Point*, pt1: G2Point*) -> (
        res: G2Point*, line_eval: E12full034*
    ) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        // precomputations in p :
        // let xp_bar = fq_bigint3.neg(p.x);
        // let yp_prime = fq_bigint3.inv(p.y);
        // let xp_prime = fq_bigint3.mul(xp_bar, yp_prime);
        // paper algo:

        let C = compute_slope(pt0, pt1);
        // let D = e2.add(pt0.x, pt1.x);
        // let nx = e2.square(C);
        // let nx = e2.sub(nx, D);

        let nx = e2.square_min_add(C, pt0.x, pt1.x);

        // let E = e2.mul(C, pt0.x);
        // let E = e2.sub(E, pt0.y);
        let E = e2.mul_sub(C, pt0.x, pt0.y);
        // let ny = e2.mul(C, nx);
        // let ny = e2.sub(E, ny);
        let ny = e2.sub_mul(E, C, nx);
        // assert_on_curve(res);

        // let F = e2.mul_by_element(xp_prime, C);
        // let G = e2.mul_by_element(yp_prime, E);
        // let one_e2 = e2.one();
        local res: G2Point = G2Point(nx, ny);
        // local line_eval: E4 = E4(C, E);
        tempvar nine = 9;
        local line_eval034: E12full034 = E12full034(
            w1=BigInt3(
                C.a0.d0 - nine * C.a1.d0, C.a0.d1 - nine * C.a1.d1, C.a0.d2 - nine * C.a1.d2
            ),
            w3=BigInt3(
                E.a0.d0 - nine * E.a1.d0, E.a0.d1 - nine * E.a1.d1, E.a0.d2 - nine * E.a1.d2
            ),
            w7=C.a1,
            w9=E.a1,
        );
        return (&res, &line_eval034);
    }
    // Computes (p1 + p2) + p1 instead of (p1+p1) + p2
    func double_and_add_step{range_check_ptr}(p1: G2Point*, p2: G2Point*) -> (
        res: G2Point*, l1: E12full034*, l2: E12full034*
    ) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        let lambda1 = compute_slope(p1, p2);
        let x3 = e2.square_min_add(lambda1, p1.x, p2.x);
        // omit y3 computation

        // compute lambda2= -lambda1 - ((2*p1.y) / (x3 - p1.x))

        let n = e2.double(p1.y);
        let d = e2.sub(x3, p1.x);
        let lambda2 = e2.div(n, d);
        let lambda2 = e2.add(lambda2, lambda1);
        let lambda2 = e2.neg(lambda2);

        // compute x4 = lambda2^2 - x1 - x3
        let x4 = e2.square_min_add(lambda2, p1.x, x3);

        // compute y4 = lambda2 * (x1 - x4) - y1

        let y4 = e2.mul_sub0_sub1(lambda2, p1.x, x4, p1.y);

        local res: G2Point = G2Point(x4, y4);
        // assert_on_curve(&res);

        let l1r1 = e2.mul_sub(lambda1, p1.x, p1.y);
        let l2r1 = e2.mul_sub(lambda2, p1.x, p1.y);
        // local l1: E4 = E4(lambda1, l1r1);
        // local l2: E4 = E4(lambda2, l2r1);
        tempvar nine = 9;
        local l1034: E12full034 = E12full034(
            w1=BigInt3(
                lambda1.a0.d0 - nine * lambda1.a1.d0,
                lambda1.a0.d1 - nine * lambda1.a1.d1,
                lambda1.a0.d2 - nine * lambda1.a1.d2,
            ),
            w3=BigInt3(
                l1r1.a0.d0 - nine * l1r1.a1.d0,
                l1r1.a0.d1 - nine * l1r1.a1.d1,
                l1r1.a0.d2 - nine * l1r1.a1.d2,
            ),
            w7=lambda1.a1,
            w9=l1r1.a1,
        );

        local l2034: E12full034 = E12full034(
            w1=BigInt3(
                lambda2.a0.d0 - nine * lambda2.a1.d0,
                lambda2.a0.d1 - nine * lambda2.a1.d1,
                lambda2.a0.d2 - nine * lambda2.a1.d2,
            ),
            w3=BigInt3(
                l2r1.a0.d0 - nine * l2r1.a1.d0,
                l2r1.a0.d1 - nine * l2r1.a1.d1,
                l2r1.a0.d2 - nine * l2r1.a1.d2,
            ),
            w7=lambda2.a1,
            w9=l2r1.a1,
        );

        return (&res, &l1034, &l2034);
    }
    func line_compute{range_check_ptr}(p1: G2Point*, p2: G2Point*) -> E12full034* {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        let lambda = compute_slope(p2, p1);
        let l1r1 = e2.mul_sub(lambda, p1.x, p1.y);
        // local l1: E4 = E4(lambda, l1r1);
        tempvar nine = 9;
        local l1034: E12full034 = E12full034(
            w1=BigInt3(
                lambda.a0.d0 - nine * lambda.a1.d0,
                lambda.a0.d1 - nine * lambda.a1.d1,
                lambda.a0.d2 - nine * lambda.a1.d2,
            ),
            w3=BigInt3(
                l1r1.a0.d0 - nine * l1r1.a1.d0,
                l1r1.a0.d1 - nine * l1r1.a1.d1,
                l1r1.a0.d2 - nine * l1r1.a1.d2,
            ),
            w7=lambda.a1,
            w9=l1r1.a1,
        );
        return &l1034;
    }
}

// Returns the generator point of G2
func get_g2_generator{range_check_ptr}() -> G2Point* {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    local g2x0: BigInt3;
    local g2x1: BigInt3;
    local g2y0: BigInt3;
    local g2y1: BigInt3;
    %{
        import subprocess
        import functools
        import re
        from starkware.cairo.common.cairo_secp.secp_utils import split

        def rgetattr(obj, attr, *args):
            def _getattr(obj, attr):
                return getattr(obj, attr, *args)
            return functools.reduce(_getattr, [obj] + attr.split('.'))
        def rsetattr(obj, attr, val):
            pre, _, post = attr.rpartition('.')
            return setattr(rgetattr(obj, pre) if pre else obj, post, val)
        def fill_element(element:str, value:int):
            s = split(value)
            for i in range(3): rsetattr(ids,element+'.d'+str(i),s[i])

        fill_element('g2x0', 10857046999023057135944570762232829481370756359578518086990519993285655852781)
        fill_element('g2x1', 11559732032986387107991004021392285783925812861821192530917403151452391805634)
        fill_element('g2y0', 8495653923123431417604973247489272438418190587263600148770280649306958101930)
        fill_element('g2y1', 4082367875863433681332203403145435568316851327593401208105741076214120093531)
    %}
    tempvar res: G2Point* = new G2Point(new E2(g2x0, g2x1), new E2(g2y0, g2y1));
    return res;
}

func get_n_g2_generator{range_check_ptr}(n: felt) -> G2Point* {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    local g2x0: BigInt3;
    local g2x1: BigInt3;
    local g2y0: BigInt3;
    local g2y1: BigInt3;
    %{
        from starkware.cairo.common.cairo_secp.secp_utils import split
        import subprocess
        import functools
        import re
        def rgetattr(obj, attr, *args):
            def _getattr(obj, attr):
                return getattr(obj, attr, *args)
            return functools.reduce(_getattr, [obj] + attr.split('.'))
        def rsetattr(obj, attr, val):
            pre, _, post = attr.rpartition('.')
            return setattr(rgetattr(obj, pre) if pre else obj, post, val)
        def parse_fp_elements(input_string:str):
            pattern = re.compile(r'\[([^\[\]]+)\]')
            substrings = pattern.findall(input_string)
            sublists = [substring.split(' ') for substring in substrings]
            sublists = [[int(x) for x in sublist] for sublist in sublists]
            fp_elements = [x[0] + x[1]*2**64 + x[2]*2**128 + x[3]*2**192 for x in sublists]
            return fp_elements
        def fill_element(element:str, value:int):
            s = split(value)
            for i in range(3): rsetattr(ids,element+'.d'+str(i),s[i])

        cmd = ['./tools/gnark/main', 'nG1nG2', '1', str(ids.n)]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 6

        fill_element('g2x0', fp_elements[2])
        fill_element('g2x1', fp_elements[3])
        fill_element('g2y0', fp_elements[4])
        fill_element('g2y1', fp_elements[5])
    %}
    tempvar res: G2Point* = new G2Point(new E2(g2x0, g2x1), new E2(g2y0, g2y1));
    return res;
}
