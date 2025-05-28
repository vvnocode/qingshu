package org.qingshu.server.framework.common.exception;

/**
 * 全局错误码枚举
 * 0-999 系统异常编码保留
 *
 * 一般情况下，使用 HTTP 响应状态码 https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status
 * 虽然说，HTTP 响应状态码作为业务使用表达能力偏弱，但是使用在系统层面还是非常不错的
 * 比较特殊的是，因为之前一直使用 0 作为成功，就不使用 200 了
 *
 * @author vvnocode
 */
public enum GlobalErrorCodeConstants implements ErrorCode {

    // ========== 通用成功 ==========
    SUCCESS(0, "成功"),

    // ========== 系统模块 1-001-000-000 ==========
    INTERNAL_SERVER_ERROR(1_001_000_000, "系统异常"),
    NOT_IMPLEMENTED(1_001_000_001, "功能未实现/未开启"),
    ERROR_CONFIGURATION(1_001_000_002, "错误的配置项"),

    // ========== HTTP 客户端错误段 1-001-001-000 ==========
    BAD_REQUEST(1_001_001_000, "请求参数不正确"),
    UNAUTHORIZED(1_001_001_001, "账号未登录"),
    FORBIDDEN(1_001_001_002, "没有该操作权限"),
    NOT_FOUND(1_001_001_003, "请求未找到"),
    METHOD_NOT_ALLOWED(1_001_001_004, "请求方法不正确"),
    LOCKED(1_001_001_005, "请求失败，请稍后重试"), // 并发请求，不允许
    TOO_MANY_REQUESTS(1_001_001_006, "请求过于频繁，请稍后重试"),

    // ========== 用户模块 1-002-000-000 ==========
    USER_NOT_EXISTS(1_002_000_000, "用户不存在"),
    USER_USERNAME_EXISTS(1_002_000_001, "用户名已存在"),
    USER_EMAIL_EXISTS(1_002_000_002, "邮箱已存在"),
    USER_MOBILE_EXISTS(1_002_000_003, "手机号已存在"),
    USER_STATUS_DISABLED(1_002_000_004, "用户已被禁用"),

    // ========== 模板模块 1-003-000-000 ==========
    TEMPLATE_NOT_EXISTS(1_003_000_000, "模板不存在"),
    TEMPLATE_NAME_EXISTS(1_003_000_001, "模板名称已存在"),
    TEMPLATE_CATEGORY_NOT_EXISTS(1_003_000_002, "模板分类不存在"),
    TEMPLATE_STATUS_DISABLED(1_003_000_003, "模板已被禁用");

    private final Integer code;
    private final String msg;

    GlobalErrorCodeConstants(Integer code, String msg) {
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