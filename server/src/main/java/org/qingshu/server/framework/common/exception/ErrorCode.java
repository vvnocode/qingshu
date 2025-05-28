package org.qingshu.server.framework.common.exception;

/**
 * 错误码对象
 *
 * 全局错误码，占用 [0, 999], 参见 {@link GlobalErrorCodeConstants}
 * 业务异常错误码，占用 [1 000 000 000, +∞)，参见 {@link ServiceErrorCodeConstants}
 *
 * TODO 错误码设计成对象的原因，为未来的 i18 国际化做准备
 *
 * @author vvnocode
 */
public interface ErrorCode {

    /**
     * 获得错误码
     *
     * @return 错误码
     */
    Integer getCode();

    /**
     * 获得错误提示
     *
     * @return 错误提示
     */
    String getMsg();

    /**
     * 错误码的默认实现类
     */
    class ErrorCodeImpl implements ErrorCode {
        private final Integer code;
        private final String msg;

        public ErrorCodeImpl(Integer code, String msg) {
            this.code = code;
            this.msg = msg;
        }

        @Override
        public Integer getCode() {
            return code;
        }

        @Override
        public String getMsg() {
            return msg;
        }
    }
}