# IHW 2
# ------- Task 1 - 3
#d - density
#p - func
#q - quantile
#r - sample

# Grid (step 1/1000) -> 6000 steps -> (-3,3) 
# c() - array
# indexing from 1 
x <- -3 + c(0:1000) / 1000 * 6
# vectorzed calculation
y <- dnorm(x)

plot(x=x, y=y, type="l", main="T2-distribution (pdf)", ylab="PDF", lwd=2)

df <- c(2, 5, 7, 10, 50)
ldf <- length(df)
clr = c("red", "blue", "green", "orange", "magenta")

for (i in 1:ldf) {
    y <- dt(x, df[i])
    points(x, y, type="l", col=clr[i])
}

legend("topleft", legend=c("N(0,1)", paste0("Student ", df, " df")), col=c("black", clr), cex=1, lwd=2)

###
n <- 100
a <- 2
sig <- 4

x <- rnorm(n, a, sig)

# EDF
n <- length(x)

ef <- ecdf(x)
ef(1.35)

plot.ecdf(x, cex=.2, pch=NA, main="Empirical cumulative distribution")

xs <- sort(x)
ys <- c(0:(n - 1))/n

points(xs, ys, cex=.2, pch=19)
# Not in practice
x1 <- -10 + c(0:1000) / 1000 * 30
y <- pnorm(x1, a, sig)
points(x1, y, "l", col="red")

# HIST
hist(x, breaks=7, probability=TRUE)

# Groups 
# brk <- min(x) + c(0:7) / 7 * (max(x) - min(x))
# hist(x, breaks=brk, probability=TRUE)
y <- dnorm(x1, a, sig)
points(x1, y, type="l", col="red", lwd=2)

dn <- density(x)
points(dn, col="green", type="l", lwd=2)

dn1 <- density(x, bw=2)
points(dn1, col="blue", type="l", lwd=2)

### Характеристики
# Asy = E(X-EX)^3 / (DX)^3/2
# Exc = (E(X-EX)^4 / (DX)^2) - 3
# Нужна выборочная дисперсия (не Var, так как это исправленная Ч.Х.)

m <- mean(x)
# m <- sum(x)/length(x)
s2 <- mean(x^2) - m^2

# Можно так:
# s2_ <- (n - 1) * var(x) / n

asy <- mean((x-m)^3) / s2^(3/2)
exc <- (mean((x-m)^4) / s2^2) - 3

# Промежуток (выборочная оценка вероятности)
pr <- sum((x >= 0 & x <= 4))/n

# Median
# med = ???

# ------ Task 4
# вывести ОМП, подставить значения и т.д, дов. интервалы точные (для параметров норм.распред., вывести значения)
n <- length(x)
m <- mean(x)
s1 <- sqrt(s2)
al <- 0.005
xal <- qnorm(1 - al/2)
d <- s1 * xal / sqrt(n - 1)
xal1 <- qchisq(al/2, n - 1)
# lower.tail=True : Функция распределения, lower.tail=False : 1 - F(x)
xal2 <- qchisq(al/2, n - 1, lower.tail=FALSE)
ns2 <- n * s2

CI <- data.frame("PAR"=c("mean", "var") ,"LOWER"=c(m - d, ns2/xal2), "UPPER"=c(m + d, ns2/xal1))
# names(CI)[2,3] <- c("2.5%%", "97.5%")

# ---- Task 5 (статистика Колмагорова D_n = sup_x |F_n(x) - F_0(x)|) 

# ---- H_0: F=F_0 (X ~ N(a0, sig0^2)) (подставляем значения в отчете) 

# Построить таблицу (вывести в отчет 1-2 строки (где будет максимум))
# | v1    |  v2        | v2          | v3 | v4    | v5      |  v6     | v7          |
# | X_(1) | F_n(X_(1)) | F_n(X_(i)+) | F_0(X_(1)) | |v2-v4| | |v3-v4| | max(v5, v6) |
# |.................................................................................|
# |...................................................................| P_n         |

# + вывести sqrt(n)D_n, x_alpha: phi(x) = {0, 1 (критерий), p-value

xs <- sort(x)

a0 <- 2
sig0 <- 4

v2 <- c(0:(n - 1))/n
v3 <- c(1:n)/n
v4 <- pnorm(xs, a0, sig0)
v5 <- abs(v2 - v4)
v6 <- abs(v3 - v4)
v7 <- pmax(v5, v6)
Dn <- max(v7)

t.ks <- data.frame("X"=xs, "Fn"=v2, "Fn1"=v3, "F0"=v4, "abs(Fn - 0)"=v5, "abs(Fn1 - F0)"=v6, "M"=v7)
t.ks[t.ks$M==Dn,]

# Сама статистика
Dnn <- sqrt(n) * Dn
print(Dnn)

pkolm <- function(x, n) {
    stats:::pkolmogorov(x, n)
}

qkolm <- function(q, n) {
    uniroot(function(x){pkolm(x,n)- q}, c(0, 1))$root
}
xal <- qkolm(1 - al, n)
print(xal)
Dnn
print(Dnn > xal)
xal <- qkolm(1 - al, n) * sqrt(n)
pval <- 1 - pkolm(Dn, n)
print(Dnn)
print(xal)
print(pval)

pnormpar <- function(x) {
    pnorm(x, a0, sig0)
}

# # pkolmogorov_lim ... 

# qkolmogorov <- function(q, v) {
#     uniroot(function(x){pkolmogorov_lim(x, n) - q}, c(0, 1))$root
# }

# xal <- qkolmogorov(1 - al, n)
# предельное значение 
# pv <- 1 - pkolmogorov_lim(sqrt(n) * Dn) 

ks.test(x, pnormpar)

# --------- Task 6
# H_0: X ~ N(a0, sig0^2) - запись правильной гипотезы обязательная в отчете 

# Критерий хи-квадрат разбивает на группы 
# не более 6 интервалов

# далее считаем в каждом интервале (ню_i - число наблюдений в интервале)

# v1 | v2 | ... | vr |
# I_1| I_2| ... | I_r| (sum = 1)

# Chi^2 = \sum{i=1}^{r} \frac{(v_i - np_i)^2}{np_i} \Rightarrow Chi^2_{r-1}

# phi(x) = {1 , x^2 > x_alpha; 0, x^2 <= x_alpha}

# x_alpha = K^-1_r-1 (1-alpha)
# pv = 1 - K_r-1 (x^2)

# Еще таблицу:

# v1. v2.  v3.    v4.  v5.    v6.                             v7
# lw | np | v_i | p_i | np_i | (v_i - np_i / sqrt(n * p_i)) | v6^2 | (просуммировав получим статистику Chi^2)

# удобнее с гистограммой (но на сам график не обращаем внимания чисто для значений)
h <- hist(x, plot=F)
brk <- h$breaks
lb <- length(brk)

# '-' - убераем элимент
brk <- brk[-c(2, 3, lb - c(3:1))]
h1 <- hist(x, breaks=brk ,plot=F)
lb <- length(brk)
nu <- h1$counts
brk[1] <- -Inf
brk[lb] <- Inf

p0 <- pnorm(brk[2, lb], a0, sig0) - pnorm(brk[1:(lb - 1)], a0, sig0)
np0 <- n * p0
res <- (nu - np0) / sqrt(np0)
res2 <- res^2

t.chisq <- data.frame("LW"=brk[1:(lb-1)], "UPPER"=brk[2:lb], "Obs"=nu, "P0"=p0, "Exp"=np0, "RES"=res, "RES2"=res2)
S.csq <- sum(res2)
df <- lb - 2
xal <- qchisq(1 - al, lb - 2)
pv <- pchisq(S.csq, df, lower.tail=F)

# Хи-квадрат: сложная гипотеза

# H: X ~ N(a, sig^2) при некоторых (a, sig^2)

# # Chi^2 (theta) = \sum{i=1}^{r} \frac{(v_i - np_i (theta))^2}{np_i (theta)} \Rightarrow Chi^2_{r-1}

# Нельзя оценивать параметр theta! 

# Либо сделать \hat{X} = min (Chi^2 (theta)) либо \wave{X} = \Chi^2 (\wave(theta)) (тета с волной это ОМП по группам ) и написать в виде функции + написать функцию и после минимизировать ее по параметру

# Задача 8 +- теоретическая и выписать ее со всеми условиями границ.
