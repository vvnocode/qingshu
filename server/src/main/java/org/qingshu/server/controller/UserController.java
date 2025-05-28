package org.qingshu.server.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.web.bind.annotation.*;
import org.qingshu.server.dal.dataobject.UserDO;
import org.qingshu.server.framework.common.pojo.CommonResult;
import org.qingshu.server.service.UserService;


import jakarta.validation.Valid;

/**
 * 用户控制器
 *
 * @author vvnocode
 */
@Tag(name = "用户管理", description = "用户相关接口")
@RestController
@RequestMapping("/users")
@Slf4j
public class UserController {

    @Resource
    private UserService userService;

    @PostMapping("/create")
    @Operation(summary = "创建用户", description = "创建新用户")
    public CommonResult<Long> createUser(@Valid @RequestBody UserDO userDO) {
        Long userId = userService.createUser(userDO);
        return CommonResult.success(userId);
    }

    @PutMapping("/update")
    @Operation(summary = "更新用户", description = "更新用户信息")
    public CommonResult<Boolean> updateUser(@Valid @RequestBody UserDO userDO) {
        userService.updateUser(userDO);
        return CommonResult.success(true);
    }

    @DeleteMapping("/delete/{id}")
    @Operation(summary = "删除用户", description = "根据ID删除用户")
    public CommonResult<Boolean> deleteUser(@Parameter(description = "用户ID") @PathVariable("id") Long id) {
        userService.deleteUser(id);
        return CommonResult.success(true);
    }

    @GetMapping("/get/{id}")
    @Operation(summary = "获取用户", description = "根据ID获取用户信息")
    public CommonResult<UserDO> getUser(@Parameter(description = "用户ID") @PathVariable("id") Long id) {
        UserDO user = userService.getUser(id);
        return CommonResult.success(user);
    }

    @GetMapping("/get-by-username")
    @Operation(summary = "根据用户名获取用户", description = "根据用户名获取用户信息")
    public CommonResult<UserDO> getUserByUsername(@Parameter(description = "用户名") @RequestParam("username") String username) {
        UserDO user = userService.getUserByUsername(username);
        return CommonResult.success(user);
    }

    @GetMapping("/get-by-email")
    @Operation(summary = "根据邮箱获取用户", description = "根据邮箱获取用户信息")
    public CommonResult<UserDO> getUserByEmail(@Parameter(description = "邮箱") @RequestParam("email") String email) {
        UserDO user = userService.getUserByEmail(email);
        return CommonResult.success(user);
    }

    @GetMapping("/get-by-mobile")
    @Operation(summary = "根据手机号获取用户", description = "根据手机号获取用户信息")
    public CommonResult<UserDO> getUserByMobile(@Parameter(description = "手机号") @RequestParam("mobile") String mobile) {
        UserDO user = userService.getUserByMobile(mobile);
        return CommonResult.success(user);
    }

} 