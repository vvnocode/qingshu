package org.qingshu.server.framework.mybatis.core.util;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * 软删除工具类
 * 
 * @author vvnocode
 */
public class SoftDeleteUtils {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 判断记录是否已删除
     * 
     * @param deletedAt 删除时间戳
     * @return true-已删除，false-未删除
     */
    public static boolean isDeleted(Long deletedAt) {
        return deletedAt != null && deletedAt > 0;
    }

    /**
     * 判断记录是否未删除
     * 
     * @param deletedAt 删除时间戳
     * @return true-未删除，false-已删除
     */
    public static boolean isNotDeleted(Long deletedAt) {
        return !isDeleted(deletedAt);
    }

    /**
     * 获取当前时间戳（毫秒）
     * 
     * @return 当前时间戳
     */
    public static Long currentTimestamp() {
        return System.currentTimeMillis();
    }

    /**
     * 将删除时间戳转换为可读的日期时间字符串
     * 
     * @param deletedAt 删除时间戳
     * @return 格式化的日期时间字符串
     */
    public static String formatDeletedTime(Long deletedAt) {
        if (isNotDeleted(deletedAt)) {
            return "未删除";
        }

        LocalDateTime dateTime = LocalDateTime.ofInstant(
                Instant.ofEpochMilli(deletedAt),
                ZoneId.systemDefault());
        return dateTime.format(FORMATTER);
    }

    /**
     * 生成唯一的删除标记（基于当前时间戳+随机数）
     * 在高并发场景下避免冲突
     * 
     * @return 唯一删除标记
     */
    public static Long generateUniqueDeletedAt() {
        long timestamp = System.currentTimeMillis();
        // 添加纳秒级精度避免同一毫秒内的冲突
        long nanos = System.nanoTime() % 1000000;
        return timestamp * 1000000 + nanos;
    }
}