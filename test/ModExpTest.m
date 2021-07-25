classdef ModExpTest < matlab.unittest.TestCase
    methods (Test)
        function firstTest(testCase)
            args = {3, 5, 7};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {4, 0, 5};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {200, 202, 200};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {7, 3, 1};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));
        end

        function dataTypes(testCase)
            args = {int32(3), 3, 1};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {uint64(10), 18, 217};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {2, 3^5+1, int32(7^6)-1};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {int32(2^13), int32(3^11+1), int32(7^11)-1};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));
        end

        function negativeBase(testCase)
            args = {-1, 3, 3};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {-24, 632491, 235349192};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {-2, 5, 0};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {int32(-flintmax("single")), int32(sqrt(2^31)), int32(2^22 - 1)};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            args = {-1, intmax("uint64"), intmax("uint64")};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));
        end

        function overflowBoundaries(testCase)
            % flintmax overflow
            args = {17, 2048, 3^17};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            % int32
            a = intmax("uint32") - randi(intmax("int32"));
            args = {a - randi(1000), a - randi(100), a - randi(10)};
            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            % intmax('int64') overflow
            a = int64(4611686018427387913);
            testCase.assertTrue(a > intmax("int64") / 2 && a*2 == intmax("int64"));
            testCase.assertEqual(ModExp(a-1, a, a), powermod(a-1, a, a));

            % intmax('uint64') overflow
            a = uint64(9223372036854775823);
            testCase.assertTrue(a > intmax("uint64") / 2 && a*2 == intmax("uint64"));
            testCase.assertEqual(ModExp(a-1, a, a), powermod(a-1, a, a));
            
            % intmax('uint64') overflow
            a = intmax("uint64");
            testCase.assertEqual(ModExp(a-2, a-1, a), powermod(a-2, a-1, a));
            testCase.assertEqual(ModExp(a, a-1, a-2), powermod(a, a-1, a-2));
            testCase.assertEqual(ModExp(a-1, a, a-2), powermod(a-1, a, a-2));
        end

        function inf(testCase)
            % inf
            testCase.assertEqual(ModExp(2, 1024, 0), powermod(2, 1024, 0));
            % double > uint64 max
            testCase.assertEqual(ModExp(2, 65, 0), powermod(2, 65, 0));
            % uint64 > uint64 max
            testCase.assertEqual(ModExp(uint64(2), 65, 0), powermod(uint64(2), 65, 0));

            % > uint64 max error
            %{
            args = {2^95, 3, 4};
            testCase.assertError(@() ModExp(args{:}), "MATLAB:assertion:failed");

            args = {5, 2^111, 8};            
            testCase.assertError(@() ModExp(args{:}), "MATLAB:assertion:failed");

            args = {7, 12, 2^88};            
            testCase.assertError(@() ModExp(args{:}), "MATLAB:assertion:failed");
            %}
        end

        function uint64rand(testCase)
            r = @() rand * intmax("uint64") - randi(2^30);
            for x = 1:30
                a = r();
                b = r();
                m = r();
                testCase.assertEqual(ModExp(a, b, m), powermod(a, b, m), "a: " + a + ", exp: " + b + ", m: " + m);
            end
        end

        function varyA(testCase)
            for x = 0:200
                testCase.assertEqual(ModExp(x, 5, 9), powermod(x, 5, 9), "Failed for: " + x);
            end
        end

        function varyB(testCase)
            for x = 3:200
                testCase.assertEqual(ModExp(3, x, 8), powermod(3, x, 8), "Failed for: " + x);
            end
        end

        function varyM(testCase)
            for x = 0:200
                testCase.assertEqual(ModExp(17, 7, x), powermod(17, 7, x), "Failed for: " + x);
            end
        end

        function unsupportedDataTypes(testCase)
            %testCase.assertError(@() ModExp("1", 2, 3), "MATLAB:validators:mustBeNumeric");
            %testCase.assertError(@() ModExp(1, "2", 3), "MATLAB:validators:mustBeNumericOrLogical");
            %testCase.assertError(@() ModExp(1, 2, "3"), "MATLAB:validators:mustBeNumericOrLogical");
        end

        function unsupportedNumArgs(testCase)
            testCase.assertError(@() ModExp(), "MATLAB:minrhs");
            testCase.assertError(@() ModExp(1), "MATLAB:minrhs");
            testCase.assertError(@() ModExp(1, 2), "MATLAB:minrhs");
            testCase.assertError(@() ModExp(1, 2, 3, 4), "MATLAB:TooManyInputs");
        end

        function arrays(testCase)
            % todo: (error for now)
            %testCase.assertError(@() ModExp(1:2, 2, 3), "MATLAB:validation:IncompatibleSize");
            %testCase.assertError(@() ModExp(1, 2:3, 3), "MATLAB:validation:IncompatibleSize");
            %testCase.assertError(@() ModExp(1, 2, 3:4), "MATLAB:validation:IncompatibleSize");
        end

        function negativeInputs(testCase)
            %testCase.assertError(@() ModExp(2, -3, 4), "MATLAB:validators:mustBeNonnegative");
            %testCase.assertError(@() ModExp(2, 3, -4), "MATLAB:validators:mustBeNonnegative");
        end

        function perfDouble(testCase)
            a = double(intmax("int16"));
            args = {a-randi(10000), a-randi(10000), a-randi(10000)};
            t1 = timeit(@() powermod(args{:}));
            t2 = timeit(@()   ModExp(args{:}));

            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            expPerfGain = 19.5;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfInt32(testCase)
            a = intmax("uint32");
            args = {a-randi(10), a-randi(1000), a+randi(1000)};
            t1 = timeit(@() powermod(args{:}));
            t2 = timeit(@()   ModExp(args{:}));

            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));

            expPerfGain = 11;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain, "Failed for: " + args);
        end

        function perfInt64(testCase)
            a = intmax("uint64");
            args = {a-randi(1000), a-randi(1000), a-randi(1000)};
            t1 = timeit(@() powermod(args{:})) + timeit(@() powermod(args{:}));
            t2 = timeit(@() ModExp(args{:})) + timeit(@() ModExp(args{:}));

            expPerfGain = .105; % symbolic wins handily
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfNegative(testCase)
            args = {-905682156, 2491, 7};
            t1 = timeit(@() powermod(args{:}));
            t2 = timeit(@()   ModExp(args{:}));

            testCase.assertEqual(ModExp(args{:}), powermod(args{:}));
            expPerfGain = 24;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        % special case of N ^ 2 (mod M)
        function perfSquare(testCase)
            % 4294967295 is max number which does not overflow uint64 when squared
            args = {4294967295, 2, 431655765};
            t1 = timeit(@() powermod(args{:})) + timeit(@() powermod(args{:}));
            t2 = timeit(@()   ModExp(args{:})) + timeit(@()   ModExp(args{:}));

            testCase.assertEqual(ModExp(args{:}), uint64(powermod(args{:})));
            expPerfGain = 395;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t1/t2 + ", Exp: " + expPerfGain));
            testCase.assertGreaterThan(t1/t2, expPerfGain);
        end

        function perfModSquareSmallDiff(testCase)
            a = uint64(18446744073709551514);
            m = a + 101;
            t = 0;
            for x = 1:100
                t = t + timeit(@() ModMultiply(a, a, m));
            end

            testCase.assertEqual(ModMultiply(a, a, m), uint64(10201));
            maxTimeAllowed = .00054;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t + ", Exp: " + maxTimeAllowed));
            testCase.assertLessThan(t, maxTimeAllowed);
        end

        function perfModSquareLargeDiff(testCase)
            a = uint64(8446744073709551514);
            m = intmax("uint64");
            t = 0;
            for x = 1:100
                t = t + timeit(@() ModMultiply(a, a, m));
            end

            testCase.assertEqual(ModMultiply(a, a, m), uint64(15413306379487079616));
            maxTimeAllowed = .021;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t + ", Exp: " + maxTimeAllowed));
            testCase.assertLessThan(t, maxTimeAllowed);
        end

        function perfTimes2(testCase)
            % time ModMultiply(2, x, m)
            % commonly used by LucasPrime
            a = uint64(2);
            b = uint64(18446744073709551556);
            m = uint64(18446744073709551557);
            t = 0;
            for x = 1:100
                t = t + timeit(@() ModMultiply(a, b, m));
            end

            testCase.assertEqual(ModMultiply(a, b, m), uint64(18446744073709551555));
            maxTimeAllowed = .00047;
            testCase.log(matlab.unittest.Verbosity.Terse, string("Act: " + t + ", Exp: " + maxTimeAllowed));
            testCase.assertLessThan(t, maxTimeAllowed);
        end
    end
end
