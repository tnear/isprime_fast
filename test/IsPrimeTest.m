% Fast and mostly comprehensive tests for isprime_fast
classdef IsPrimeTest < matlab.unittest.TestCase
    properties (TestParameter)
        emptyValues = {[], double.empty(1,0), int32.empty(0,2), cell.empty};
        scalarDoubles = {0, 1, 2, 5, 10, 27, 39, 101, 121, 128, 499, 997, flintmax("single") + 2, 2^100};
        int64s = {uint64(10), int64(127), uint64(flintmax + 2), uint64(2147483659), uint64(1e6:711:1e7)};
        invalidInputs = {-1, 5.5, Inf, -1i, NaN, {1}, '1'};
        vectorInputs = {2:7, 100:100:10000, randi(1e7, 1, 255), 10000:-199:1, [1, 50000]};
        flintmaxSingle = {[7, flintmax("single") + 43]};
        sparseValues = {sparse(23), sparse(magic(4)), speye(16), sparse([1e9+3, 5])};
        dimensions = {reshape(1:120, [2 3 4 5]), reshape(1:32, [2, ones(1, 65536), 16])};
    end

    methods (Test)
        function emptyArray(testCase, emptyValues)
            testCase.assertEqual(isprime_fast(emptyValues), isprime(emptyValues));
        end
        
        function scalarDouble(testCase, scalarDoubles)
            testCase.assertEqual(isprime_fast(scalarDoubles), isprime(scalarDoubles));
        end

        function scalarInt(testCase, scalarDoubles)
            int = int32(scalarDoubles);
            testCase.assertEqual(isprime_fast(int), isprime(int));
        end

        function dimension(testCase, dimensions)
            testCase.assertEqual(isprime_fast(dimensions), isprime(dimensions));
        end

        function smallScalars(testCase)
            max = 100000;
            out = false(1, max);
            for x = 1:max
                out(x) = isprime_fast(x);
            end
            testCase.assertEqual(out, isprime(1:x));
        end

        function mediumPrimeTest(testCase)
            % medium prime is between 2^39 and 2^49
            max = 50;
            out = false(1, max);
            N = randi([2^39, 2^49], [1, max]);
            evenIdx = mod(N, 2) == 0;
            N(evenIdx) = N(evenIdx) + 1;
            for x = 1:numel(N)
                out(x) = isprime_fast(N(x));
            end
            testCase.assertEqual(out, isprime(sym(N)), "Failed for: " + N);
        end
        
        function smallVector(testCase)
            range = 0:150000;
            testCase.assertEqual(isprime_fast(range), isprime(range));
        end

        function vecWithOne(testCase)
            range = [1, 100001];
            testCase.assertEqual(isprime_fast(range), isprime(range));
        end

        function vectorInput(testCase, vectorInputs)
            testCase.assertEqual(isprime(vectorInputs), isprime_fast(vectorInputs));
        end

        function flintmaxBoundaries(testCase, flintmaxSingle)
            testCase.assertEqual(isprime(flintmaxSingle), isprime_fast(flintmaxSingle));
        end

        function matrixInput(testCase)
            testCase.assertEqual(isprime(magic(100)), isprime_fast(magic(100)));
        end

        function Int64(testCase, int64s)
            testCase.assertEqual(isprime(int64s), isprime_fast(int64s));
        end

        function Int64Array(testCase)
            range = [uint64(flintmax) + 1, nextprime(uint64(1.9e16))];
            testCase.assertEqual(isprime(range), isprime_fast(range));
        end

        function invalidInput(testCase, invalidInputs)
            testCase.assertError(@() isprime_fast(invalidInputs), "MATLAB:isprime:InputNotPosInt");
        end

        function sparse(testCase, sparseValues)
            testCase.assertEqual(isprime_fast(sparseValues), isprime(sparseValues));
        end

        function perfScalarPow2(testCase)
            num = int64(2)^48;
            expPerfGain = 10100;
            t2 = measureSmallNumPerf(testCase, num, expPerfGain, 2);

            % symbolic
            sNum = sym(num);
            t3 = timeit(@() isprime(sNum)) + timeit(@() isprime(sNum));
            t3 = t3/2;
            expPerfGainOverSym = 325;
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfTinyPrime(testCase)
            expPerfGain = 5.22;
            measureSmallNumPerf(testCase, 211, expPerfGain, 50);
        end

        function perfSmallPrime(testCase)
            expPerfGain = 5.95;
            measureSmallNumPerf(testCase, 200713, expPerfGain, 50);
        end

        function perfSmallPrime2(testCase)
            expPerfGain = 4.11;
            measureSmallNumPerf(testCase, 32770037, expPerfGain, 75);
        end

        function perfUint32(testCase)
            p = prevprime(intmax("uint32"));
            expPerfGain = 4;
            measureSmallNumPerf(testCase, p, expPerfGain, 25);
        end

        function perfTinyComposite(testCase)
            expPerfGain = 5.15;
            measureSmallNumPerf(testCase, 221, expPerfGain, 50);
        end

        function perfSmallComposite(testCase)
            expPerfGain = 6.56;
            measureSmallNumPerf(testCase, 132869, expPerfGain, 50);
        end

        function perfSmallComposite2(testCase)
            expPerfGain = 5.6;
            measureSmallNumPerf(testCase, 211914403, expPerfGain);
        end

        function perfSmallComposite3(testCase)
            expPerfGain = 6.6;
            measureSmallNumPerf(testCase, 23^7, expPerfGain);
        end

        function perfBits24(testCase)
            % non-prime
            % factor(12165779) == [53, 53, 61, 71]
            num = 12165779;
            expPerfGain = 6.2;
            measureSmallNumPerf(testCase, num, expPerfGain, 70);

            % semiprime
            % factor(9296257) == [3037, 3061]
            num = 9296257;
            expPerfGain = 6.12;
            measureSmallNumPerf(testCase, num, expPerfGain, 70);

            % prime
            num = 9213791;
            expPerfGain = 6.12;
            measureSmallNumPerf(testCase, num, expPerfGain, 75);
        end

        function perfBits28(testCase)
            % non-prime
            % factor(156512119) == [97, 109, 113, 131]
            num = 156512119;
            expPerfGain = 6.6;
            measureSmallNumPerf(testCase, num, expPerfGain, 30);

            % semiprime
            % factor(182131009) == [13001, 14009]
            num = 182131009;
            expPerfGain = 7.5;
            measureSmallNumPerf(testCase, num, expPerfGain, 30);

            % prime
            num = 178956937;
            expPerfGain = 7.55;
            measureSmallNumPerf(testCase, num, expPerfGain, 30);
        end

        function perfScalarInt32Prime(testCase)
            % medium prime
            prime = 2^31-1;
            expPerfGain = 8.2;
            t2 = measureSmallNumPerf(testCase, prime, expPerfGain);

            % symbolic
            sNum = sym(prime);
            t3 = timeit(@() isprime(sNum)) + timeit(@() isprime(sNum));
            t3 = t3/2;
            expPerfGainOverSym = 374;
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfBits36(testCase)
            % non-prime
            % factor(37208267497) == [401, 431, 461, 467]
            num = 37208267497;
            expPerfGain = 4;
            measureSmallNumPerf(testCase, num, expPerfGain);

            % semiprime
            % factor(46896109787) == [206783, 226789]
            num = 46896109787;
            expPerfGain = 3.85;
            measureSmallNumPerf(testCase, num, expPerfGain);

            % prime
            num = nextprime(4.7e10);
            expPerfGain = 3.8;
            measureSmallNumPerf(testCase, num, expPerfGain);
        end

        function perfSmallFactorBits36(testCase)
            % factor(47000000019) == [3, 7, 21247, 105337]
            num = 47000000019;
            expPerfGain = 322; % was: 338; % 390;
            measureSmallNumPerf(testCase, num, expPerfGain, 40);
        end

        function perfSemiprimeBits41(testCase)
            % medium semiprime which is factor of primes and greater than uint32 max
            num = 1524119*1524119;
            expPerfGain = 2.64;
            t2 = measureSmallNumPerf(testCase, num, expPerfGain);

            % symbolic
            sNum = sym(num);
            t3 = timeit(@() isprime(sNum)) + timeit(@() isprime(sNum)) + timeit(@() isprime(sNum));
            t3 = t3/3;
            expPerfGainOverSym = .79; % symbolic wins
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfBits45(testCase)
            % non-prime
            % factor(34761317881879) == [2027, 2111, 2707, 3001]
            num = 34761317881879;
            expPerfGain = 2.8;
            measureSmallNumPerf(testCase, num, expPerfGain, 3);

            % semiprime
            % factor(34877694075691) == [5031659, 6931649]
            num = 34877694075691;
            expPerfGain = 2.73;
            measureSmallNumPerf(testCase, num, expPerfGain, 3);

            % prime
            num = 34877694075703;
            expPerfGain = 2.7;
            measureSmallNumPerf(testCase, num, expPerfGain, 3);
        end

        function perfPrimeBits49(testCase)
            prime = uint64(562949953421231);
            expPerfGain = 2.41;
            measureSmallNumPerf(testCase, prime, expPerfGain, 1);
        end

        function perfSparseTiny(testCase)
            s = sparse(113);
            expPerfGain = 4;
            measureSmallNumPerf(testCase, s, expPerfGain, 40);
        end

        function perfSparseMed(testCase)
            s = sparse([1e9+3, 5]);
            expPerfGain = 2.2;
            measureSmallNumPerf(testCase, s, expPerfGain);
        end

        function perfCompositeBits53(testCase)
            % large Mersenne non-prime
            num = uint64(2)^53-1;
            tic;
            isp1 = isprime(num); isprime(num);
            t1 = toc;
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(num)) + timeit(@() isprime_fast(num));
            t2 = t2/2;

            testCase.assertEqual(isp1, isprime_fast(num));
            expPerfGain = 42;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);

            % symbolic
            sNum = sym(num);
            t3 = timeit(@() isprime(sNum)) + timeit(@() isprime(sNum));
            t3 = t3/2;
            expPerfGainOverSym = .161; % symbolic wins handily
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfPrimeBits53(testCase)
            % medium prime
            prime = uint64(9007199254740997);
            tic;
            isp1 = isprime(prime); isprime(prime);
            t1 = toc;
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(prime)) + timeit(@() isprime_fast(prime));
            t2 = t2/2;

            testCase.assertEqual(isp1, isprime_fast(prime));
            expPerfGain = 23.5;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);

            % symbolic
            sNum = sym(prime);
            t3 = timeit(@() isprime(sNum)) + timeit(@() isprime(sNum));
            t3 = t3/2;
            expPerfGainOverSym = .57;
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfBits63(testCase)
            % non-prime
            % factor(sym('9034301440688367703')) == [54001, 55001, 55103, 55201]
            num = uint64(9034301440688367703);
            expPerfGain = .155;
            measureSymbolic(testCase, num, expPerfGain);

            % semiprime
            % factor(sym('9223372037000249951')) == [3037000493, 3037000507]
            num = uint64(9223372037000249951);
            expPerfGain = .183;
            measureSymbolic(testCase, num, expPerfGain);

            % prime
            prime = uint64(9223372036854775783);
            expPerfGain = .165;
            measureSymbolic(testCase, prime, expPerfGain);
        end

        function perfLargestPrimes(testCase)
            % largest uint64 prime
            prime = uint64(18446744073709551557);
            expPerfGain = .133;
            measureSymbolic(testCase, prime, expPerfGain);

            prime = uint64(18446744073709551533);
            expPerfGain = .174;
            measureSymbolic(testCase, prime, expPerfGain);
        end

        function perfOldPathInt32(testCase)
            % sqrt path, with N < int32 max
            range = 1e9 + (1:5000);
            tic;
            isp1 = isprime(range);
            t1 = toc;
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/2;

            testCase.assertEqual(isp1, isprime_fast(range));
            expPerfGain = 27.6;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);

            sRange = sym(range);
            tic;
            isprime(sRange);
            t3 = toc;
            expPerfGainOverSym = 170;
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfOldPathInt64(testCase)
            % sqrt path with N > uint32
            range = 21294967295 + (2:8:2000);
            t1 = timeit(@() isprime(range));
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/2;

            testCase.assertEqual(isprime(range), isprime_fast(range));
            expPerfGain = 7;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);
        end

        function perfArray1(testCase)
            % sqrt path
            range = randi([7e6, 1e7], 1, 450);
            range(mod(range, 2) == 0) = range(mod(range, 2) == 0) + 1; % make odd
            t1 = timeit(@() isprime(range)) + timeit(@() isprime(range));
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/2;

            expPerfGain = 10.8;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);

            % symbolic
            sRange = sym(range);
            numTrials = 7;
            tic;
            for x = 1:numTrials
                isprime(sRange);
            end
            t3 = toc;
            t3 = t3/numTrials;
            expPerfGainOverSym = 595;
            testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t3/t2 + ", Exp: " + expPerfGainOverSym));
            testCase.verifyGreaterThan(t3/t2, expPerfGainOverSym);
        end

        function perfArray2(testCase)
            % sqrt path
            range = randi(1e8, 1, 14000);
            tic;
            isp1 = isprime(range); isprime(range);
            t1 = toc;
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range)) + ...
                 timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/4;

            testCase.assertEqual(isp1, isprime_fast(range));
            expPerfGain = 28.5; % volatile due to randi
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);
        end

        function perfArray3(testCase)
            % sqrt path
            range = randi(1e7, 1, 5000);
            t1 = timeit(@() isprime(range));
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/3;

            testCase.assertEqual(isprime(range), isprime_fast(range));
            expPerfGain = 25;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);
        end

        function perfArrayInt32Odd(testCase)
            % sqrt path near threshold
            range = randi([1e5, 1e6], 1, 4000);
            range = int32(range);
            evenIdx = mod(range, 2) == 0;
        	range(evenIdx) = range(evenIdx) + 1;
            expPerfGain = 1.52; % before: 1.92;
            measureSmallNumPerf(testCase, range, expPerfGain, 8);
        end

        function perfArrayUint32(testCase)
            % sqrt path
            range = uint32(3147473647):2:3147483647;
            t1 = timeit(@() isprime(range));

            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/2;
            expPerfGain = 2.05;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);
        end

        function perfNormDistrib(testCase)
            % ismember path
            input = randi([2^17 2^18], [1 200000]);
            % make input odd
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            % remove (most) small primes
            input(mod(input, 11) == 0) = input(mod(input, 11) == 0) + 2;
            input(mod(input, 9) == 0) = input(mod(input, 9) == 0) + 2;
            input(mod(input, 7) == 0) = input(mod(input, 7) == 0) + 2;
            input(mod(input, 5) == 0) = input(mod(input, 5) == 0) + 2;
            input(mod(input, 3) == 0) = input(mod(input, 3) == 0) + 2;

            tic;
            isprime(input);
            isprime(input);
            t1 = toc;
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(input)) + timeit(@() isprime_fast(input)) + timeit(@() isprime_fast(input));
            t2 = t2/3;
            
            expPerfGain = 49;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);
        end

        function shortTinyPrimeArray(testCase)
            % Short array of tiny primes
            % ismember path
            input = int16(1000):2500;
            input = nextprime(input);
            input = unique(input);
            testCase.assertLength(input, 200);
            expPerfGain = 3.66;
            measureSmallNumPerf(testCase, input, expPerfGain, 40);
        end

        function perfSequenceShort(testCase)
            % ismember path
            range = 1:10000;
            expPerfGain = 33.3;
            measureSmallNumPerf(testCase, range, expPerfGain, 4);
        end

        function perfSequenceMed(testCase)
            % ismember path
            range = 1:100000;
            expPerfGain = 70;
            measureSmallNumPerf(testCase, range, expPerfGain, 1);
        end

        function perfSequence(testCase)
            % ismember path
            range = 1:200000;
            tic;
                   isprime(range);
            isp1 = isprime(range);
            t1 = toc;
            t1 = t1/2;
            t2 = timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range)) + ...
                timeit(@() isprime_fast(range)) + timeit(@() isprime_fast(range));
            t2 = t2/4;

            testCase.assertEqual(isp1, isprime_fast(range));
            expPerfGain = 91.3;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.verifyGreaterThan(t1/t2, expPerfGain);

            % tic, isprime_fast(1:10000000); toc
            % Elapsed time is 1.318615 seconds. (Feb 10, 2021)
            % Elapsed time is 0.679211 seconds. (Apr 4)
            % Elapsed time is 0.611921 seconds. (Apr 6)
        end
    end
end

function t2 = measureSmallNumPerf(testCase, number, expPerfGain, numTrials)
    arguments
        testCase;
        number;
        expPerfGain;
        numTrials = 20;
    end

    [t1, t2] = measureWithTimeIt(number, numTrials);
    testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));

    if t1/t2 < expPerfGain
        disp 'Retrying with twice as many trials...'
        numTrials = numTrials * 2;
        [t1, t2] = measureWithTimeIt(number, numTrials);
        testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
    end

    testCase.verifyGreaterThan(t1/t2, expPerfGain);
    if t1/t2 > expPerfGain * 1.7
        warning("Possible performance improvement");
    end

    % return average speed of isprime_fast
    t2 = t2 / numTrials;
end

function [t1, t2] = measureWithTimeIt(num, numTrials)
    t1 = 0;
    t2 = 0;
    for x = 1:numTrials
        t1 = t1 + timeit(@() isprime(num));
        t2 = t2 + timeit(@() isprime_fast(num));
    end
end

function measureSymbolic(testCase, num, expPerfGain)
    symNum = sym(num);
    t1 = timeit(@() isprime(symNum)) + timeit(@() isprime(symNum));
    t1 = t1/2;
    t2 = timeit(@() isprime_fast(num));
    testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t1/t2 + ", Exp: " + expPerfGain));

    if t1/t2 < expPerfGain
        disp 'Retrying with twice as many trials...'
        t1 = timeit(@() isprime(symNum)) + timeit(@() isprime(symNum)) + timeit(@() isprime(symNum)) + timeit(@() isprime(symNum));
        t1 = t1/4;
        t2 = timeit(@() isprime_fast(num)) + timeit(@() isprime_fast(num));
        t2 = t2/2;
        testCase.log(matlab.unittest.Verbosity.Terse, string("SymAct: " + t1/t2 + ", Exp: " + expPerfGain));
    end

    testCase.assertEqual(isprime_fast(num), isprime(symNum));
    testCase.verifyGreaterThan(t1/t2, expPerfGain);
    if t1/t2 > expPerfGain * 1.7
        warning("Possible performance improvement");
    end
end
