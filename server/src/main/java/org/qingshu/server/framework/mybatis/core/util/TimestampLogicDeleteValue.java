package org.qingshu.server.framework.mybatis.core.util;

import org.springframework.stereotype.Component;

/**
 * 时间戳逻辑删除值生成器
 * 用于 MyBatis-Plus 的 @TableLogic 注解
 * 
 * @author vvnocode
 */
@Component("timestampLogicDeleteValue")
public class TimestampLogicDeleteValue {

    /**
     * 获取删除时的时间戳值
     * 
     * @return 当前时间戳（毫秒）
     */
    public Long get() {
        return System.currentTimeMillis();
    }
}