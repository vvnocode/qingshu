+++
date = '2024-11-07T19:57:04+08:00'
draft = false
title = 'Java Ftp连接池'
+++
某项目由于网络关系，传输文件通过ftp方式，即第三方实时把碎片文件放到ftp，我方需要把ftp文件下载下来进行业务处理。每个文件在100KB左右，每日文件数量在300万左右。前同事直接用在网上找的ftp demo，每次上传/下载文件创建新的连接，且单线程处理文件导致处理性能在1个文件每秒左右。当我们发现时，堆积的文件已经快撑爆了ftp服务器。

所以需要对现有代码进行优化。将现有的单线程改为多线程，每处理一个文件就启动一个线程来处理。创建ftp连接池，为每个线程提供单独的ftp连接。当线程下载/上传完成一个文件后，立即将连接还给Ftp连接池，提供连接池复用效率。

### 优化Ftp服务器配置

如果采用多线程消费ftp上文件，并且采用ftp连接池维护ftp连接，需要确认ftp服务的配置是否支持多个连接。项目采用vsftpd，所以需要查看/etc/vsftpd/vsftpd.conf配置文件。

- pasv\_max\_port=0
  设置在PASV工作方式下，数据连接可以使用的端口范围的上界。默认值为0，表示任意端口。
- pasv\_mim\_port=0
  设置在PASV工作方式下，数据连接可以使用的端口范围的下界。默认值为0，表示任意端口。
- max_clients=0
  设置vsftpd允许的最大连接数，默认为0，表示不受限制。若设置为150时，则同时允许有150个连接，超出的将拒绝建立连接。只有在以standalone模式运行时才有效。
- max\_per\_ip=0
  设置每个IP地址允许与FTP服务器同时建立连接的数目。默认为0，不受限制。通常可对此配置进行设置，防止同一个用户建立太多的连接。只有在以standalone模式运行时才有效。

配置完成后重启ftp服务。如果ftp连接失败，可以检查是否是防火墙/安全策略限制了端口放行。

### 连接池

#### 引入Maven

```xml
<!-- https://mvnrepository.com/artifact/commons-net/commons-net -->
<dependency>
    <groupId>commons-net</groupId>
    <artifactId>commons-net</artifactId>
    <version>3.10.0</version>
</dependency>
```

#### Ftp连接配置

```java
import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
@Data
public class FtpProperties {
    @Value("${ftp.hostname}")
    private String host;
    @Value("${ftp.username}")
    private String username;
    @Value("${ftp.password}")
    private String password;
    @Value("${ftp.port}")
    private int port;
    @Value("${ftp.timeout.default.seconds:1200}")
    private Integer defaultTimeoutSecond = 1200;
    @Value("${ftp.timeout.connect.seconds:1800}")
    private Integer connectTimeoutSecond = 1800;
    @Value("${ftp.timeout.data.seconds:2400}")
    private Integer dataTimeoutSecond = 2400;
    @Value("${ftp.charSet:UTF-8}")
    private String charSet = "UTF-8";
    @Value("${ftp.factory.thread.times:2}")
    private Integer threadTimes = 2;
}
```

#### Ftp连接对象

```java
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;

import java.io.IOException;
import java.io.OutputStream;
import java.net.UnknownHostException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * ftp连接
 */
@Slf4j
public class FtpConnection {

    private final FTPClient ftp = new FTPClient();

    private final AtomicBoolean isConnected = new AtomicBoolean(false);

    /**
     * 构造函数
     */
    public FtpConnection(FtpProperties ftpProperties) {
        ftp.setDefaultTimeout(ftpProperties.getDefaultTimeoutSecond() * 1000);
        ftp.setConnectTimeout(ftpProperties.getConnectTimeoutSecond() * 1000);
        ftp.setDataTimeout(ftpProperties.getDataTimeoutSecond() * 1000);
        ftp.setCharset(Charset.forName(ftpProperties.getCharSet()));
        ftp.setControlEncoding(ftpProperties.getCharSet());
        //被动模式
        ftp.enterLocalPassiveMode();
        try {
            initConnect(ftpProperties.getHost(), ftpProperties.getPort(),
                    ftpProperties.getUsername(), ftpProperties.getPassword());
        } catch (IOException e) {
            isConnected.set(false);
            log.error("init ftp client error", e);
        }
    }

    /**
     * 初始化连接
     */
    private void initConnect(String host, int port, String user, String password) throws IOException {
        try {
            ftp.connect(host, port);
        } catch (UnknownHostException ex) {
            throw new IOException("Can't find FTP server '" + host + "'");
        }
        int reply = ftp.getReplyCode();
        if (!FTPReply.isPositiveCompletion(reply)) {
            disconnect();
            throw new IOException("Can't connect to server '" + host + "'");
        }
        if (!ftp.login(user, password)) {
            isConnected.set(false);
            disconnect();
            throw new IOException("Can't login to server '" + host + "'");
        } else {
            isConnected.set(true);
        }
    }

    public List<String> fileNames(String path) {
        try {
            //获取文件列表使用这个接口最好，命令行效率更高
            String[] strings = ftp.listNames(path);
            return strings == null ? new ArrayList<>() : Stream.of(strings).collect(Collectors.toList());
        } catch (IOException e) {
            log.error("ftp listNames error.path = {}", path);
            return new ArrayList<>();
        }
    }

    public String download(String path, String ftpFileName, String localPath, boolean deleteSuccessFile, boolean deleteErrorFile) {
        String fileName = localPath + ftpFileName.substring(path.length());
        boolean deleted = false;
        try (OutputStream os = Files.newOutputStream(Paths.get(fileName))) {
            //保存文件
            boolean success = ftp.retrieveFile(ftpFileName, os);
            if (success) {
                //是否需要删除源文件
                if (deleteSuccessFile) {
                    deleted = delete(ftpFileName);
                }
                return fileName;
            }
        } catch (Exception e) {
            log.error("ftp download error", e);
            if (deleteErrorFile) {
                //对于下载失败的文件直接删除
                deleted = delete(ftpFileName);
            }
        } finally {
            if (deleteSuccessFile || deleteErrorFile) {
                log.debug("ftp download then delete file {}", deleted ? "success" : "failed");
            }
        }
        return null;
    }

    public boolean delete(String ftpFileName) {
        try {
            ftp.deleteFile(ftpFileName);
            return true;
        } catch (IOException e) {
            log.error("delete ftp file error", e);
        }
        return false;
    }

    /**
     * 关闭连接
     */
    public void disconnect() {
        if (ftp.isConnected()) {
            try {
                ftp.logout();
                ftp.disconnect();
                isConnected.set(false);
            } catch (IOException e) {
                log.error("ftp disconnect error", e);
            }
        }
    }

    /**
     * 设置工作路径
     */
    private boolean setWorkingDirectory(String dir) {
        if (!isConnected.get()) {
            return false;
        }
        //如果目录不存在创建目录
        try {
            if (createDirectory(dir)) {
                return ftp.changeWorkingDirectory(dir);
            }
        } catch (IOException e) {
            log.error("set working directory error", e);
        }
        return false;

    }

    /**
     * 是否连接
     */
    public boolean isConnected() {
        return isConnected.get();
    }

    /**
     * 创建目录
     */
    private boolean createDirectory(String remote) throws IOException {
        boolean success = true;
        String directory = remote.substring(0, remote.lastIndexOf("/") + 1);
        // 如果远程目录不存在，则递归创建远程服务器目录
        if (!directory.equalsIgnoreCase("/") && !ftp.changeWorkingDirectory(directory)) {
            int start = 0;
            int end;
            if (directory.startsWith("/")) {
                start = 1;
            }
            end = directory.indexOf("/", start);
            do {
                String subDirectory = remote.substring(start, end);
                if (!ftp.changeWorkingDirectory(subDirectory)) {
                    if (ftp.makeDirectory(subDirectory)) {
                        ftp.changeWorkingDirectory(subDirectory);
                    } else {
                        log.error("mack directory error :/" + subDirectory);
                        return false;
                    }
                }
                start = end + 1;
                end = directory.indexOf("/", start);
                // 检查所有目录是否创建完毕
            } while (end > start);
        }
        return success;
    }
}
```

#### Ftp工厂

```java
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.locks.ReentrantLock;


/**
 * ftp连接工厂
 */
@Slf4j
@NoArgsConstructor
public class FtpFactory {
    /**
     * 存放ftp连接有界队列
     */
    private ArrayBlockingQueue<FtpConnection> arrayBlockingQueue;
    private FtpProperties ftpProperties;
    /**
     * 最大连接数在初始化的时候固定，除非删除，否则不能新增连接
     */
    private int maxSize;
    /**
     * 工厂含有的连接数(包括已经取出的)
     */
    private int ftpSize = 0;

    private final ReentrantLock lock = new ReentrantLock(false);

    public FtpFactory(FtpProperties ftpProperties) {
        this.ftpProperties = ftpProperties;
        //最大数量为处理器线程数*配置的倍数
        this.maxSize = Runtime.getRuntime().availableProcessors() * ftpProperties.getThreadTimes();
        this.arrayBlockingQueue = new ArrayBlockingQueue<>(maxSize);
        //初始化一个客户端，节约资源。后续需要更多再追加。
        this.fill(1);
    }

    /**
     * 扩容工厂的连接池
     *
     * @param size 扩容连接数量至
     */
    public void fill(int size) {
        if (size <= 0) {
            return;
        }
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            for (int i = 0; i < size; i++) {
                if (ftpSize >= size || ftpSize >= maxSize) {
                    break;
                }
                //表示如果可能的话，将 e 加到 BlockingQueue 里，即如果 BlockingQueue 可以容纳，则返回 true，否则返回 false
                FtpConnection connection = new FtpConnection(ftpProperties);
                boolean offer = this.safeOffer(connection);
                if (!offer) {
                    break;
                } else {
                    ftpSize++;
                }
            }
            log.info("Fill ftpConnection end, size is {}.", ftpSize);
        } finally {
            lock.unlock();
        }
    }

    /**
     * 将ftp连接放入队列，如果超过队列大小将会销毁连接
     *
     * @param connection
     * @return 是否加入成功
     */
    private boolean safeOffer(FtpConnection connection) {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            boolean offer = arrayBlockingQueue.offer(connection);
            if (!offer) {
                log.debug("offer ftpConnection failed");
                connection.disconnect();
            }
            return offer;
        } finally {
            lock.unlock();
        }
    }

    /**
     * 获取连接(阻塞)
     */
    public FtpConnection getFtp() {
        FtpConnection poll;
        try {
            //取走 BlockingQueue 里排在首位的对象，若 BlockingQueue 为空，阻断进入等待状态直到 Blocking 有新的对象被加入为止
            poll = arrayBlockingQueue.take();
        } catch (InterruptedException e) {
            log.error("getFtpConnection error", e);
            return null;
        }
        return poll;
    }

    /**
     * 释放连接
     *
     * @param ftp
     */
    public void safeRelease(FtpConnection ftp) {
        this.safeOffer(ftp);
    }

    /**
     * 关闭连接
     */
    public void close() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            for (FtpConnection connection : arrayBlockingQueue) {
                connection.disconnect();
            }
            arrayBlockingQueue.clear();
            ftpSize = 0;
        } finally {
            lock.unlock();
        }
    }

}
```

### 工厂使用

#### 使用方式

- 获取连接
  FtpConnection connection = ftpFactory.getFtp();
- 归还连接
  ftpFactory.safeRelease(connection);
- 扩容连接池
  ftpFactory.fill(50);
  50代表想要50个连接，注意有最大限制。最大限制为FtpFactory中的maxSize，可以通过ftp.factory.thread.times配置为系统线程数的倍数。

#### 代码示例

```java
public void yourJob(FtpFactory ftpFactory, String ftpFilePath) {
	try {
        //拿到一个连接
		FtpConnection connection = ftpFactory.getFtp();
		List<String> names = connection.fileNames(ftpFilePath);
        //归还连接
		ftpFactory.safeRelease(connection);
		if (!ObjectUtils.isEmpty(names)) {
			ftpFactory.fill(names.size());
			CountDownLatch countDownLatch = new CountDownLatch(names.size());
			Logger.info("本次文件路径 {}, 总数 {}, 开始处理", ftpFilePath, names.size());
			long start = System.currentTimeMillis();
			for (String fileName : names) {
				ftpThreadPool.execute(
						() -> {
                            //这里传入ftpFactory是为了从工厂拿到连接和归还连接
							yourService.downloadAndAnalysis(ftpFactory, ftpFilePath, fileName);
							countDownLatch.countDown();
						});
			}
			countDownLatch.await();
			double seconds = (System.currentTimeMillis() - start) / 1000.0;
			Logger.info("完成文件路径 {}, 总数 {}, 耗时 {} 秒, 速度 {} 条/s",
					ftpFilePath, names.size(), seconds, names.size() / seconds);
		} else {
			Logger.error("ftp文件为空ftpFilePath：{}", ftpFilePath);
		}
	} catch (Exception e) {
		Logger.error("同步图片数据异常", e);
	}
}
```

### 参考

- [ftp配置文件](https://www.cnblogs.com/zhouhbing/p/5564512.html)
- [Java 多线程实现FTP批量上传文件](https://blog.csdn.net/weixin_44656112/article/details/121606915)
- [vsftpd并发参数调优](https://blog.csdn.net/ory001/article/details/108253821)