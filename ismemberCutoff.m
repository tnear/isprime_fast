classdef ismemberCutoff < matlab.unittest.TestCase
    methods (Test)
        function random32BitPrimes(~)
            input = randi([1, 2^32], [1, 10000]);
            input = nextprime(input);
            input = repmat(input, [1 85]); % 850,000 primes
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % 28 seconds
        end

        function randomOdd(~)
            input = randi([2^19 2^21], [1 10000]);
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            t1 = timeit(@() isprimeTemp(input)) + timeit(@() isprimeTemp(input));
            t2 = timeit(@() isprime_fast(input)) + timeit(@() isprime_fast(input));
            % .008 seconds
        end

        function randomOddSmallPrimesRemoved(~)
            input = randi([2^22 2^27], [1 185000]);
            % make input odd
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            % remove (most) small primes
            input(mod(input, 11) == 0) = input(mod(input, 11) == 0) + 2;
            input(mod(input, 9) == 0) = input(mod(input, 9) == 0) + 2;
            input(mod(input, 7) == 0) = input(mod(input, 7) == 0) + 2;
            input(mod(input, 5) == 0) = input(mod(input, 5) == 0) + 2;
            input(mod(input, 3) == 0) = input(mod(input, 3) == 0) + 2;

            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % .8 seconds
        end

        function randomTo233(~)
            input = randi(2^33, [1 5000000]);
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % 66 seconds
        end

        function randomOddTo233(~)
            input = randi(2^33, [1 2530000]);
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % 73 seconds
        end

        function random29To30(~)
            input = randi([2^29, 2^30], [1 2400000]);
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % 7.3 seconds
        end

        function randMax100K(~)
            input = randi([1, 100000], [1, 1000]);
            timeit(@() isprimeTemp(input))
            timeit(@() isprime_fast(input))
            % 0.0005 seconds
        end

        function randOddMax10K(~)
            input = randi([1, 10000], [1, 125]);
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            loops = 100;
            t1 = 0;
            for x = 1:loops
                t1 = t1 + timeit(@() isprimeTemp(input));
            end
            disp(t1);

            t2 = 0;
            for x = 1:loops
                t2 = t2 + timeit(@() isprime_fast(input));
            end
            disp(t2);
            % .001 seconds
        end

        function normDistrib(~)
            input = abs(floor(normrnd(1e8, 1e7, [1, 650000])));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
            % .8 seconds
        end

        function normDistribSmallOdd(~)
            input = abs(floor(normrnd(100000, 50000, [1, 1350])));
            input(mod(input, 2) == 0) = input(mod(input, 2) == 0) + 1;
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            numLoops = 50;
            t1 = 0;
            for x = 1:numLoops
            	t1 = t1 + timeit(@() isprimeTemp(input));
            end
            t2 = 0;
            for x = 1:numLoops
                t2 = t2 + timeit(@() isprime_fast(input));
            end

            disp(t1);
            disp(t2);
        end

        function oddUint32(testCase)
            input = uint32(3144483647):2:3147483647;
            disp(size(input));
            tic, isprimeTemp(input); toc
            tic, isprime_fast(input); toc
        end
        
        function bestFit(~)
            close all;
            % raw data:
            %numElements = [125, 1000,      1350, 10000, 185000, 650000, 850000, 1500000, 2400000, 2530000, 5000000];
            %maxValue =    [10000, 100000, 270000, 2^21, 2^27, 150000000, 2^32,    3.1e9,    2^30,   2^33,   2^33];
            %  data used for best fit:
            numElements = [125,     1000, 1350, 10000, 185000, 650000, 2400000, 5000000];
            maxValue =    [10000, 100000, 270000, 2^21, 2^27, 150000000, 2^30, 2^32];
            oldHeuristic = numElements * 500;
            xlabel('Number of elements');
            ylabel('Max value');
            % linear fit
            coefficients = polyfit(numElements, maxValue, 1);
            fittedVals = polyval(coefficients, numElements);
            hold on;
            plot(numElements, maxValue);
            plot(numElements, fittedVals);
            plot(numElements, oldHeuristic);
        end
    end
end
