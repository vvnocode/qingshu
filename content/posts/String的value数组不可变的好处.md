+++
date = '2025-01-09T17:44:00+08:00'
draft = false
title = 'String的value数组不可变的好处'
tags = ['Java', 'String', '不可变性', '源码分析']
+++
## 缓存hash值

String中用value数组来存储字符串信息，用hash来缓存value的hash值。如果value不是final，每次修改后需要重新计算hash，失去了缓存的意义，影响程序运行效率。

```java
//java9及之后采用byte[],之前是char[]
private final byte[] value;
private int hash; // Default to 0
public int hashCode() {
	int h = hash;
	if (h == 0 && value.length > 0) {
		hash = h = isLatin1() ? StringLatin1.hashCode(value)
							: StringUTF16.hashCode(value);
	}
	return h;
}
```

## String Pool（常量池）复用需要

String Pool可以缓存已经创建的String对象。只有 String 是不可变的，才可能使用 String Pool。

![image.png](static/images/2026/01/3aff6e0cbd11e96a6e7e8e181956bb21_MD5.png)

## 安全性

由于String对象在创建后不可被修改，因此对于String类型的参数，其不可变性可以保证参数不会被意外或恶意地改变。

在网络连接过程中，一般需要传递服务器地址、端口号、用户名、密码等各种参数。如果这些参数使用可变的String类型来表示，那么在连接过程中，这些参数可能会被改变，导致实际连接的主机不同于预期。例如，某个客户端使用一个可变的String类型来表示服务器地址，然后在连接过程中修改了该字符串，将原本应该连接的服务器地址改成了另一个地址，从而导致最终连接到了错误的服务器上。

如果使用不可变的String类型来表示这些参数，则可以避免上述问题的出现。由于String对象不可被修改，因此无论在何种情况下都可以确保连接所需的参数不会在连接过程中被更改，从而确保连接行为的正确性和稳定性。

## 多线程

由于String的不可变，String具备线程安全性，可以在多线程中使用。