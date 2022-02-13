% Utility class used to create performance tables and plots for research paper
classdef perfPrime < matlab.unittest.TestCase
    methods (Static)
        function [tIsPrime, tIsPrimeFast, tSymIsPrime] = perfScalar(numBits, typeCheck)
            % typeCheck = 0: random prime numbers (often worse-case)
            % typeCheck = 1: random odd numbers
            % typeCheck = 2: random numbers
            % ex usage: [tIsPrime, tIsPrimeFast, tSymIsPrime] = perfPrime.perfScalar(32, 0)
            tIsPrime = [];
            tIsPrimeFast = [];
            tSymIsPrime = [];
            for idx = 1:100
                [x, y, z] = getPerf(numBits, typeCheck);
                tIsPrime = [tIsPrime, x]; %#ok<AGROW>
                tIsPrimeFast = [tIsPrimeFast, y]; %#ok<AGROW>
                tSymIsPrime = [tSymIsPrime, z]; %#ok<AGROW>
            end
            tIsPrime = mean(tIsPrime);
            tIsPrimeFast = mean(tIsPrimeFast);
            tSymIsPrime = mean(tSymIsPrime);
        end
    end

    methods (Test)
        function incrementingSequence(~)
            arr = 1:10000000;
            % 139 seconds
            tic, isprime(arr); toc;

            tic, isprime_fast(arr); toc;
            % .660 seconds

            sArr = sym(arr);
            tic, isprime(sArr); toc; 
        end

        function int32Matrix(~)
            range = randi(intmax('int32'), [1000, 1000], 'int32');
            tic, isprime(range); toc
            % Elapsed time is 17.686067 seconds.
            tic, isprime_fast(range); toc
            % Elapsed time is 3.927214 seconds.

            sRange = sym(range);
            tic, isprime(sRange); toc
        end

        function oneHundredLargestPrimes(~)
            % 100 largest primes
            prime = zeros(1, 100, 'uint64');
            prime(1) = prevprime(uint64(inf));
            for x = 2:100
                prime(x) = prevprime(prime(x-1)) - 1;
            end


            tic, isprime(prime); toc
            % Elapsed time is 206.562121 seconds.

            timeit(@() isprime_fast(prime))
            % 0.1442

            sPrime = sym(prime);
            timeit(@() isprime_fast(sPrime))
            % 0.0284
        end

        function oneHundredPseudoPrimesBelowFlintmax(~)
            % find pseudoprimes with high (> 20M) factors
            % flintmax = 2^53
            found = [];
            start = uint64(2^53);
            x = 1;
            while numel(found) ~= 100
                num = start + x;
                f = factor(sym(num));
                f = double(f);
                if numel(f) == 2 && f(1) > 20000000
                    disp(int64(num));
                    found = [found, num]; %#ok<AGROW>
                end
                x = x + 2;
            end
        end

        function loadFlintmax(testCase)
            pseudoprimes = load("greaterThanFlintmax.mat").found;
            testCase.assertLength(pseudoprimes, 100);
            tic, isprime(pseudoprimes); toc
            tic, isprime_fast(pseudoprimes); toc
            sPseudoprimes = sym(pseudoprimes);
            tic, isprime(sPseudoprimes); toc
        end

        function normalDistribBits16(~)
            % Normal distribution of 1 million primes with mean 2^16
            input = abs(floor(normrnd(2^16, 2^13, [1, 10000])));
            input = nextprime(input);
            input = repmat(input, [1, 100]);
            disp(size(input));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprime(input); toc
            timeit(@() isprime_fast(input))
            %sInput = sym(input);
            %tic, isprime(sInput); toc
            % 11 seconds
        end

        function normalDistribBits32(~)
            % Normal distribution of 100,000 random odd numbers with mean 2^32
            input = abs(floor(normrnd(2^32, 2^30, [1, 100000])));
            % convert to odd numbers
            evenIdx = mod(input, 2) == 0;
            input(evenIdx) = input(evenIdx) + 1;
            disp(size(input));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprime(input); toc
            tic, isprime_fast(input); toc
            %sInput = sym(input);
            %tic, isprime(sInput); toc
            % 21 seconds
        end

        function normalDistribBits53(~)
            % Normal distribution of 1,000 random odd numbers with mean 2^53
            input = abs(floor(normrnd(2^53, 2^51, [1, 1000])));
            disp(size(input));
            disp("Max: " + max(input));
            disp("Min: " + min(input));
            tic, isprime(input); toc
            tic, isprime_fast(input); toc
            % 80 seconds
        end

        function shortTinyPrimeArray(testCase)
            % Short array of tiny primes
            input = int16(1000):2500;
            input = nextprime(input);
            input = unique(input);
            testCase.assertLength(input, 200);
            sInput = sym(input);

            t1 = 0;
            t2 = 0;
            numTrials = 50;
            for x = 1:numTrials
                t1 = t1 + timeit(@() isprime(input));
                t2 = t2 + timeit(@() isprime_fast(input));
            end
            t1 = t1/numTrials;
            t2 = t2/numTrials;
            t3 = timeit(@() isprime(sInput));
            disp(t1);
            disp(t2);
            disp(t3);
        end

        function largest64BitOddNumbers(testCase)
            numElements = 100;
            input = intmax("uint64") : -2 : intmax("uint64") - 2 * numElements + 2;
            testCase.assertNumElements(input, numElements);
            tic, isprime(input); toc
            tic, isprime_fast(input); toc
            sInput = sym(input);
            tic, isprime(sInput); toc

            % isprime:
            % 100 elements, 201 seconds
            % 1000 elements, 1736 seconds
            % 5000 elements, 8816 seconds
        end

        function plotOfPrimeOddEven(~)
            % perfPrime.plotOfPrimeOddEven
            close all;
            numBits = [4 8 16 24 32 36 40 44 48 50 52 56 60 64];

            % isprime_fast times faster over isprime for each bit size
            primeNum = [6.07 5.63 6.49 7.52 7.65 3.89 2.45 3.00 2.90 5.83 9.21 32.9 98.6 266 ];
            oddNum = [5.82 5.56 6.68 13.1 18.1 17.0 5.48 6.98 7.1 25 51 192 564 1620] ;
            randNum = [7.39 7.64 10.7 21.7 31.9 16.5 12.4 14.7 15.1 52.6 94.4 340 1122 2953];

            lineWidth = 1.8;
            semilogy(numBits, primeNum, "LineWidth", lineWidth);
            hold on;
            grid on;
            semilogy(numBits, oddNum, "LineWidth", lineWidth, "LineStyle", "--");
            semilogy(numBits, randNum, "LineWidth", lineWidth, "LineStyle", "-.");
            %title("isprime\_fast speedup factor compared to isprime", "FontSize", 12);
            yticklabels([1, 10, 100, 1000, 10000]);
            xlabel("Bit-size of scalar input");
            ylabel("Number of times faster");
            legend(["Random prime numbers", "Random odd numbers", "Random numbers"], ...
                "Location", "northwest", "FontSize", 11);
        end
    end
end

function [tIsPrime, tIsPrimeFast, tSymIsPrime] = getPerf(numBits, typeCheck)
    low = 2^(numBits - 1);
    high = 2^numBits - 1;
    num = 4; % placeholder value
    if numBits >= 53
        if typeCheck == 0
            num = uint64(2)^numBits - randi(2^53 - 1);
            num = prevprime(num);
        elseif typeCheck == 1
            while mod(num, 2) == 0
                % randi only supports < 2^53
                % instead take high number and subtract largest randi range
                % this skews data toward high side of numBits, but it sufficient
                % for basic performance testing
                num = uint64(2)^numBits - randi(2^53 - 1);
            end
        else
            num = uint64(2)^numBits - randi(2^53 - 1);
        end
    else
        if typeCheck == 0
            num = nextprime(randi([low, high]));
        elseif typeCheck == 1
            while mod(num, 2) == 0
                num = randi([low, high]);
            end
        else
            num = randi([low, high]);
        end
    end

    if typeCheck == 0
        assert(isprime(sym(num)));
    elseif typeCheck == 1
        assert(mod(num, 2) == 1);
    end

    if num < 2^47
        tIsPrime = timeit(@() isprime(num));
    else
        % isprime becomes a little slow for timeit
        tic;
        isprime(num);
        tIsPrime = toc;
    end
    tIsPrimeFast = timeit(@() isprime_fast(num));
    sNum = sym(num);
    tSymIsPrime = timeit(@() isprime(sNum));
end
