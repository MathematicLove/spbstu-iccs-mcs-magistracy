### ИДЗ 3

# Генерируем данные: 
sig <- 5
b1 <- 10
b2 <- 2
b3 <- 1
al <- 0.05

x <- round(rnorm(100, 5, 1), digits=2)
y <- b1 + b2*x + b3*x^2 + rnorm(100, 0, sig)
dat <- data.frame(Y=y, X=x)
# количество наблюдений
n <- dim(dat)[1]

print(dat)

# визуализация
plot(dat$X, dat$Y, xlab="z", ylab="Y", main="Regression")

# 1) Линейная модель
# Метод 1: Вручную строим
# byrow=True - запись по рядам
XM <- matrix(c(array(1, dim=n), dat$X), nrow=2, byrow=T)
print(XM[, c(1:10)])

# Оценка: \hat{beta} = (XX^T)^-1 XY
YM <- as.matrix(dat$Y)
S <- XM%*%t(XM)
# solve - обратная матрица
S1 <- solve(S)

# %*% - матричное умножение как @ в numpy
bhat <- S1%*%XM%*%YM
print(bhat)

mx <- min(dat$X)
Mx <- max(dat$X)
x <- c(mx, Mx)
y <- bhat[1] + bhat[2] * x
points(x, y, "l", col="red", lwd=2)

# Метод 2
# lm() - линейная модель
# Получили тоже самое
ql <- lm(Y~X, data=dat)
print(ql$"coefficients")
ql.s <- summary(ql)
ql.a <- anova(ql)
ql.i <- confint(ql)

# Информация о параметрах (средне квадрат. откл.)
print(ql.s)
# Дисперсионный анализ (результат проверки гипотезы, значение статистики, сумма квадратов, ср.сумма.квадратов, SSe, \line{SSe})
print(ql.a)
# Частные дов. интервалы для параметров модели 
print(ql.i)

# Остатки
res <- YM - t(XM)%*%bhat
SSE <- sum(res^2)
dfe <- n - length(bhat)
# SSE с чертой (несмещенная оценка)
MSSE <- SSE / dfe
print(MSSE)
# Получаем тоже самое
# ql.s$sigma^2

# cov.unscaled из summary - матрица оценок B которая в лекциях была (B - матрица S1)
# S1 - матрица ковариации коэффициентов
print(ql.s$cov.unscaled)
# В 1 пункте - выводим параметры

### 2) Квадратичная (полиномиальная модель)

XM <- matrix(c(array(1, dim=n), dat$X, dat$X^2), nrow=3, byrow=T)

YM <- as.matrix(dat$Y)
S <- XM%*%t(XM)
# solve - обратная матрица
S1 <- solve(S)

# %*% - матричное умножение как @ в numpy
bhat <- S1%*%XM%*%YM
print(bhat)

mx <- min(dat$X)
Mx <- max(dat$X)

x <- mx + c(1:1000) / 1000 * (Mx - mx)
y <- bhat[1] + bhat[2] * x + bhat[3] * x^2
points(x, y, "l", col="blue", lwd=2)

#### Анализ остатков (нормальность остатков) (только для квадратичной делаем)
res <- YM - t(XM)%*%bhat
SSE <- sum(res^2)
dfe <- n - length(bhat)
# SSE с чертой (несмещенная оценка)
MSSE <- SSE / dfe
# MSSE - оценка s^2 (несмещенная оценка дисперсии)
s2 <- MSSE
s1 <- sqrt(MSSE)

# 3) остатки
## Считаем что остатки независимы, проведем критерий на нормальность 
## H_0: e~N(0, sig^2), sig > 0

h <- hist(res, probability=TRUE, ylim=c(0, 0.08))
x <- -20 + c(0:1000) / 1000 * 40
y <- dnorm(x, 0, 5)
y1 <- dnorm(x, 0, s1)
points(x, y, "l", col="red")
points(x, y1, "l", col="blue")

# Метод lm() делает то же самое что и код ниже*
qs <- lm(Y~I(X) + I(X^2), data=dat)
qs.s <- summary(qs)
qs.a <- anova(qs)
qs.i <- confint(qs)

print(qs.s)
print(qs.a)
print(qs.i)

# * - вручную:
# Визуально нормально, но
# Проверяем с помощью хи-квадрат !
h$counts
brk <- h$breaks
lb <- length(brk)
brk <- brk[-c(2, 3, (lb-1), (lb-2))]
h <- hist(res, breaks=brk, plot=F)
lb <- length(brk)
brk[1] <- -Inf
brk[lb] <- Inf
nu <- h$counts

csq.f <- function(x) {
    # 0 т.к. среднее = 0
    p <- pnorm(brk[2:lb], 0, x) - pnorm(brk[1:lb - 1], 0, x)
    np <- n * p
    sum((nu - np)^2 / np)
}

# nlm() - минимизация
# Обязательно строим таблицу !!! 
q <- nlm(csq.f, s1)
X2 <- q$minimum
print(X2)

xal <- pchisq(al, lb - 3,lower.tail=F)
pval <- pchisq(X2, lb - 3)
stilde <- q$estimate
# Нижние и верхние границы
lw <- c(brk[1:lb - 1])
up <- c(brk[2:lb])
# Вероятности 
pr <- pnorm(brk[2:lb], 0, stilde) - pnorm(brk[1:lb - 1], 0, stilde)
ex <- n * pr
res1 <- (nu - ex) / sqrt(ex)
res2 <- res1^2
X22 <- sum(res2)

# Таблица (сумма квадратов последнего столбца = X2)
err.t <- data.frame(lw=lw, up=up, counts=nu, exp=ex, res=res1, res2=res2)
err.t

### Проверка гипотезы
xal <- qchisq(al, lb - 3, lower.tail=F)
print(xal)
pval <- pchisq(X2, lb - 3, lower.tail=F)
# pval > 0.05 - гипотезу принимаем иначе отв.
print(pval)

### Проверяем только с Хи-квадрат !

# 4) Довер. интервалы: 
# автоматически:
qs.i <- confint(qs, level=1-al)
qs.ij <- confint(qs, level=1-al/2)

# вручную: 
# считаем ковариационную матрицу, с использованием объекта qs
V <- s2 * S1

# или так: получаем тоже самое 
qs.s$cov.unscaled * qs.s$sigma^2 

# ДИ: frac{hat{beta_i} - beta_i}{sqrt(v[i])} ~ S_{n-3} => x_alpha = S^-1_{n-3} (1 - alpha/2); hat{beta_i} +- d; d = x_alpha * sqrt(v_i)
v <- diag(V)
tal <- qt(1 - al/2, n - 3)
d <- tal * sqrt(v)
# приращение
d <- d[-1]

# нижняя граница
lwb <- as.vector(bhat)[2:3] - d 
# верхняя
upd <- as.vector(bhat)[2:3] + d 

# Сам дов. интервал (такой же как в qs.i)
t.int <- data.frame(par=c("scale", "square"), lw=lwb, up=upd)

# По Бонферрони дов. интервал:
##########################################################################################################################################
## let * = (hat(beta_1) - beta_1; hat(beta_2) - beta_2)^T * hat(Гамма_{beta_1, beta_2})^-1 (hat(beta_1) - beta_1; hat(beta_2) - beta_2) ##
##########################################################################################################################################

# (hat(beta_1) - beta_1; hat(beta_2) - beta_2)^T hat(Гамма_{beta_1, beta_2})^-1 (hat(beta_1) - beta_1; hat(beta_2) - beta_2) ~ 2 F_{2, n-3}
# ,где:
# hat(Гамма_{beta_1, beta_2})^-1 = (s^2 B)^-1 = s^-2 B^-1

# x_alpha = F^-1_{2, n-3} (1-alpha)
# P(*/2 <= x_alpha) = (hat(beta) - beta)^T B^-1 (hat(beta) - beta) <= 2s^2 * x_alpha

C <- matrix(c(0, 1, 0, 0, 0, 1), nrow=3)
psihat <- t(C) %*% bhat
Bpsi <- t(C) %*% S1 %*% C
Bpsi1 <- solve(Bpsi)

xal <- qf(1 - al, 2, n - 3)
# Нормированная B_psi
Bpsi1n <- Bpsi1 / 2 / xal / s2

# To be continue...
