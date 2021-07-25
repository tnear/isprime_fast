classdef MillerRabinTest < matlab.unittest.TestCase
    properties(TestParameter)
        bugs = {3215031751, uint64(9007199254740997), uint64(3825123056546413051), uint64(15575474027814488189)};
    end

    properties (TestParameter)
        invalidInputs = {-1, 5.5, Inf, -1i, NaN, {1}, '1'};
        dataT = {int8(201), uint16(25124), int32(201^7 / 3), flintmax("single"), uint64(3^27 + 1)};
    end

    methods (Test)
        function smallNumbers(testCase)
            for x = 0:1024
                testCase.verifyEqual(MillerRabinPrime(x), isprime(x), "Failed for: " + x);
            end
        end

        %function emptyArray(testCase)
        %    testCase.assertEqual(MillerRabinPrime([]), isprime([]));
        %    testCase.assertEqual(MillerRabinPrime(uint8.empty), isprime(uint8.empty));
        %   testCase.assertEqual(MillerRabinPrime(single.empty), isprime(single.empty));
        %end

        function millerRabinFixes(testCase, bugs)
            testCase.assertEqual(MillerRabinPrime(bugs), isprime(sym(bugs)), "Failed for: " + bugs);
        end

        function dataTypes(testCase, dataT)
            testCase.assertEqual(MillerRabinPrime(dataT), isprime(dataT));
        end

        function carmichaelNumbers(testCase)
            nums = [561, 1105, 1729, 2465, 2821, 6601, 8911, 10585, 15841, ...
                29341, 41041, 46657, 52633, 62745, 63973, 75361, 101101, ...
                115921, 126217, 162401, 172081, 188461, 252601, 278545, ...
                294409, 314821, 334153, 340561, 399001, 410041, 449065, 488881];
            for num = nums
                testCase.assertFalse(MillerRabinPrime(num));
            end
        end

        %function invalidInput(testCase, invalidInputs)
        %    testCase.assertError(@() MillerRabinPrime(invalidInputs), "MATLAB:isprime:InputNotPosInt");
        %end

        %function arrays(testCase)
        %    testCase.assertError(@() MillerRabinPrime(1:2), "MATLAB:validators:mustBeScalarOrEmpty");
        %end

        function perfSmallPrime(testCase)
            num = 1303667;
            testCase.assertTrue(MillerRabinPrime(num));

            t1 = timeit(@() isprime(num));
            t2 = timeit(@() MillerRabinPrime(num));

            expPerfGain = .09; % isprime wins
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);

            % symbolic small prime
            s = sym(num);
            t1 = timeit(@() isprime(s));

            expPerfGain = 24;
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfSmallMedPrime(testCase)
            num = 4659123193;
            testCase.assertTrue(MillerRabinPrime(num));

            t1 = 0;
            t2 = 0;
            numTrials = 5;
            for x = 1:numTrials
                t1 = t1 + timeit(@() isprime(num));
                t2 = t2 + timeit(@() MillerRabinPrime(num));
            end

            t1 = t1/numTrials;
            t2 = t2/numTrials;
            expPerfGain = .57; % isprime wins
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);

            s = sym(num);
            t1 = timeit(@() isprime(s));

            expPerfGain = 33;
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfMedNonPrime(testCase)
            while true
                num = intmax("uint32") - randi(10000);
                if mod(num, 2) == 1 && ~isprime(num)
                    break;
                end
            end

            testCase.assertFalse(MillerRabinPrime(num));

            t1 = timeit(@() isprime(num));
            t2 = timeit(@() MillerRabinPrime(num));

            expPerfGain = 1.35;
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfMedPrime2(testCase)
            num = 46636622961217;
            testCase.assertTrue(MillerRabinPrime(num));
            
            t1 = timeit(@() isprime(num));
            t2 = timeit(@() MillerRabinPrime(num));

            expPerfGain = 1.5;
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);

            s = sym(num);
            t1 = timeit(@() isprime(s));

            testCase.assertTrue(MillerRabinPrime(num));
            expPerfGain = .75; % sym wins
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfLargePrime(testCase)
            num = uint64(3061837692357883);
            expPerfGain = 8.9;
            compareMillerRabinWithIsPrime(testCase, num, expPerfGain);
        end

        function perfLargePrime2(testCase)
            num = uint64(9007199254740997);
            expPerfGain = 20;
            compareMillerRabinWithIsPrime(testCase, num, expPerfGain);
        end

        function perfLargeNonPrime(testCase)
            num = uint64(2)^53-1;
            expPerfGain = 38;
            compareMillerRabinWithIsPrime(testCase, num, expPerfGain);
        end

        function symbolicComparison(testCase)
            r = @(num) rand * intmax("uint64") - randi(2^30);
            numTrials = 10;
            largeNumbers = zeros([1, numTrials], "uint64");

            out1 = largeNumbers;
            out2 = largeNumbers;
            for x = 1:numTrials
                largeNumbers(x) = r();
            end
            % convert to odd
            evenIdx = mod(largeNumbers, 2) == 0;
            largeNumbers(evenIdx) = largeNumbers(evenIdx) + 1;
            largeNumbersSym = sym(largeNumbers);

            tic;
            for x = 1:numTrials
                out1(x) = isprime(largeNumbersSym(x));
            end
            t1 = toc;
            tic;
            for x = 1:numTrials
                out2(x) = MillerRabinPrime(largeNumbers(x));
            end
            t2 = toc;

            testCase.assertEqual(out1, out2, "Trials: " + largeNumbers);
            expPerfGain = .19; % symbolic wins
            testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end
    end
end

function diagnostic = getDiagnostic(time, expGain)
    diagnostic = string("Act: " + time + ", Exp: " + expGain);
end

function compareMillerRabinWithIsPrime(testCase, num, expPerfGain)
    tic;
    isp1 = isprime(num);
    t1 = toc;
    t2 = timeit(@() MillerRabinPrime(num));
    testCase.assertEqual(MillerRabinPrime(num), isp1);

    testCase.log(matlab.unittest.Verbosity.Terse, getDiagnostic(t1/t2, expPerfGain));
    testCase.assertGreaterThan(t1/t2, expPerfGain);
end
