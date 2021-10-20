# isprime_fast

**_isprime_fast_** (https://arxiv.org/abs/2108.04791) is intended to improve the performance of MATLAB's built-in [*isprime*](https://www.mathworks.com/help/matlab/ref/isprime.html) function. *isprime_fast* uses modular arithmetic techniques, the Miller—Rabin primality test, vectorized operations, and division-minimizing strategies which harness the power of MATLAB's capabilities. *isprime_fast* requires no arbitrary-precision arithmetic, C/C++ source code, or external libraries—it is entirely implemented in MATLAB. The results are typically 5 to 10 times faster for small integers and hundreds of times faster for large integers and long arrays.

## Syntax
The syntax for *isprime_fast* is identical to *isprime*. It accepts an input array then returns which elements are prime. The only difference lies in the techniques used to determine primality.
```
>> isprime_fast([1, 2, 3, 4, 5])
ans =

  1×5 logical array

   0   1   1   0   1
```

## Performance
### Incrementing sequence
```MATLAB
>> N = 1:100000000; % 1 to 100 million
>> tic, isprime(N); toc
Elapsed time is 32898.133274 seconds.
    
>> tic, isprime_fast(N); toc
Elapsed time is 6.728862 seconds.

% 430x speedup over isprime (9 hours compared to 6.7 seconds)
```

### 64-bit integers

```MATLAB
>> N = uint64(18446744073709551557); % The largest 64-bit prime
>> tic, isprime(N); toc
Elapsed time is 31.11671 seconds.

>> tic, isprime_fast(N); toc
Elapsed time is 0.154598 seconds.

% 201x speedup over isprime


>> N = uint64(18446743979220271189); % 64-bit pseudoprime (4294967279 * 4294967291)
>> tic, isprime(N); toc
Elapsed time is 34.040376 seconds.

>> tic, isprime_fast(N); toc
Elapsed time is 0.018214 seconds.

% 1868x speedup over isprime
```

### Scalar performance comparison of various bit-sizes for *isprime_fast*, *isprime*, and Symbolic Math Toolbox's *sym/isprime*
```
Random prime numbers (2.4x to 260x isprime_fast speedup over isprime):
Bit-size  isprime_fast  isprime     Perf speedup  sym/isprime  Perf speedup
4         7.7654e-07    4.7186e-06  6.07x         0.002166     2789x
8         1.0120e-06    5.7043e-06  5.63x         0.00209      2066x
16        1.8106e-06    1.1762e-05  6.49x         0.002196     1213x
24        5.8244e-06    4.3816e-05  7.52x         0.008325     1429x
32        5.3932e-05    4.1277e-04  7.65x         0.0124       230x
36        0.0002828     0.0011006   3.89x         0.012055     42.6x
40        0.001766      0.004343    2.45x         0.016207     9.17x
44        0.005818      0.01744     3.00x         0.015349     2.64x
48        0.02718       0.07891     2.90x         0.01777      0.653x
52        0.0431        0.3973      9.21x         0.0244       0.566x
56        0.0552        1.8212      32.9x         0.0226       0.410x
60        0.0755        7.4418      98.6x         0.0280       0.370x
64        0.1194        31.8824     266x          0.0287       0.234x

Random odd numbers (5.4x to 1600x isprime_fast speedup over isprime):
Bit-size  isprime_fast  isprime     Perf speedup  sym/isprime  Perf speedup
4         7.9037e-07    4.5998e-06  5.82x         0.00211      2668x
8         9.8097e-07    5.4535e-06  5.56x         0.0020       2084x
16        1.4468e-06    9.6701e-06  6.68x         0.0020       1409x
24        2.9905e-06    3.9433e-05  13.1x         0.00299      1000x
32        1.9783e-05    3.5878e-04  18.1x         0.00298      150x
36        2.3884e-05    4.0707e-04  17.0x         0.002895     121x
40        7.2903e-04    0.0040      5.48x         0.0027       3.49x
44        0.002690      0.01878     6.98x         0.003328     1.23x
48        0.01062       0.07565     7.1x          0.002771     0.260x
52        0.007706      0.39378     51x           0.002832     0.367x
56        0.0095        1.8229      192x          0.0044       0.463x
60        0.01316       7.4327      564x          0.003645     0.277x
64        0.0196        31.7576     1620x         0.0034       0.174x

Random numbers (7.3x to 2950x isprime_fast speedup over isprime):
Bit-size  isprime_fast  isprime     Perf speedup  sym/isprime  Perf speedup
4         5.4788e-07    4.0505e-06  7.39x         0.002046     3734x
8         7.1275e-07    5.4507e-06  7.64x         0.002103     2950x
16        9.0833e-07    9.7864e-06  10.7x         0.002008     2210x
24        1.8587e-06    4.0482e-05  21.7x         0.002289     1231x
32        1.1610e-05    3.7037e-04  31.9x         0.002584     222x
36        6.9472e-05    0.001146    16.5x         0.002507     36.0x
40        3.3226e-04    0.004121    12.4x         0.002913     8.76x
44        0.001256      0.01854     14.7x         0.002359     1.87x
48        0.004622      0.06985     15.1x         0.002308     0.4993x
52        0.003863      0.3647      94.4x         0.002498     0.6467x
56        0.005152      1.7537      340x          0.003188     0.6189x
60        0.006451      7.2382      1122x         0.002881     0.4466x
64        0.01126       33.2620     2953x         0.002531     0.2247x
```

### Normal distribution of 100,000 random odd numbers with mean 2<sup>32</sup>
```MATLAB
>> input = abs(floor(normrnd(2^32, 2^30, [1, 100000])));
>> evenIdx = mod(input, 2) == 0;
>> input(evenIdx) = input(evenIdx) + 1; % convert to odd numbers

>> tic, isprime(input); toc
Elapsed time is 19.603392 seconds.

>> tic, isprime_fast(input); toc
Elapsed time is 2.689549 seconds.

% 7.28x speedup over isprime
```

##### Software & Hardware
All results were obtained using MATLAB R2020b on Windows 10, Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz 2.59 GHz, 16 GB RAM. Results were also verified on:<br/>
Windows 10, Intel(R) Xeon(R) W-2133 CPU @ 3.60GHz, 64 GB RAM<br/>
Debian GNU/Linux 10 (buster), Intel(R) Xeon(R) Gold 6140 CPU @ 2.30GHz, 51 GiB RAM<br/>
macOS Big Sur, Quad-Core Intel Core i3 @ 3.60Ghz, 32 GB RAM

##### Reproducibility
The results on both Windows hardware were mostly consistent within a few percentage points. Linux and Mac fluctuated more but *isprime_fast* continued to outperform *isprime* strongly for every performance test.
