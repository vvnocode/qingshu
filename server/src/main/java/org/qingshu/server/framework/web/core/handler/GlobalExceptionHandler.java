package org.qingshu.server.framework.web.core.handler;

import lombok.extern.slf4j.Slf4j;
import org.qingshu.server.framework.common.exception.GlobalErrorCodeConstants;
import org.qingshu.server.framework.common.pojo.CommonResult;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * 全局异常处理器
 *
 * @author vvnocode
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * 处理业务异常
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public CommonResult<?> handleIllegalArgumentException(NoResourceFoundException ex) {
        log.info("访问资源不存在：{}", ex.getMessage());
        return CommonResult.error(GlobalErrorCodeConstants.NOT_FOUND);
    }

    /**
     * 处理参数校验异常
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public CommonResult<?> handleMethodArgumentNotValidException(MethodArgumentNotValidException ex) {
        log.warn("参数校验异常", ex);
        String message = ex.getBindingResult().getFieldError() != null ?
                ex.getBindingResult().getFieldError().getDefaultMessage() : "参数校验失败";
        return CommonResult.error(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), message);
    }

    /**
     * 处理业务异常
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public CommonResult<?> handleIllegalArgumentException(IllegalArgumentException ex) {
        log.warn("业务异常：{}", ex.getMessage());
        return CommonResult.error(GlobalErrorCodeConstants.BAD_REQUEST.getCode(), ex.getMessage());
    }

    /**
     * 处理系统异常
     */
    @ExceptionHandler(Exception.class)
    public CommonResult<?> handleException(Exception ex) {
        log.error("系统异常", ex);
        return CommonResult.error(GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR);
    }

} 