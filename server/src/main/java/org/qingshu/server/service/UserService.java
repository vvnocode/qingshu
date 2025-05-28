package org.qingshu.server.service;

import org.qingshu.server.dal.dataobject.UserDO;

/**
 * 用户 Service 接口
 *
 * @author vvnocode
 */
public interface UserService {

    /**
     * 创建用户
     *
     * @param userDO 用户信息
     * @return 用户ID
     */
    Long createUser(UserDO userDO);

    /**
     * 更新用户
     *
     * @param userDO 用户信息
     */
    void updateUser(UserDO userDO);

    /**
     * 删除用户
     *
     * @param id 用户ID
     */
    void deleteUser(Long id);

    /**
     * 获得用户
     *
     * @param id 用户ID
     * @return 用户信息
     */
    UserDO getUser(Long id);

    /**
     * 根据用户名获得用户
     *
     * @param username 用户名
     * @return 用户信息
     */
    UserDO getUserByUsername(String username);

    /**
     * 根据邮箱获得用户
     *
     * @param email 邮箱
     * @return 用户信息
     */
    UserDO getUserByEmail(String email);

    /**
     * 根据手机号获得用户
     *
     * @param mobile 手机号
     * @return 用户信息
     */
    UserDO getUserByMobile(String mobile);

    /**
     * 校验用户是否存在
     *
     * @param id 用户ID
     */
    void validateUserExists(Long id);

} 