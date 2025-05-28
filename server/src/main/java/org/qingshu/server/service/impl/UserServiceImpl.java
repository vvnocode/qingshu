package org.qingshu.server.service.impl;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.qingshu.server.dal.dataobject.UserDO;
import org.qingshu.server.dal.mysql.UserMapper;
import org.qingshu.server.service.UserService;

/**
 * 用户 Service 实现类
 *
 * @author vvnocode
 */
@Service
@Slf4j
public class UserServiceImpl implements UserService {

    @Resource
    private UserMapper userMapper;

    @Override
    public Long createUser(UserDO userDO) {
        // 校验用户名唯一性
        validateUsernameUnique(userDO.getUsername(), null);

        // 插入用户
        userMapper.insert(userDO);
        return userDO.getId();
    }

    @Override
    public void updateUser(UserDO userDO) {
        // 校验用户存在
        validateUserExists(userDO.getId());

        // 校验用户名唯一性
        validateUsernameUnique(userDO.getUsername(), userDO.getId());

        // 更新用户
        userMapper.updateById(userDO);
    }

    @Override
    public void deleteUser(Long id) {
        // 校验用户存在
        validateUserExists(id);

        // 删除用户
        userMapper.deleteById(id);
    }

    @Override
    public UserDO getUser(Long id) {
        return userMapper.selectById(id);
    }

    @Override
    public UserDO getUserByUsername(String username) {
        return userMapper.selectByUsername(username);
    }

    @Override
    public UserDO getUserByEmail(String email) {
        return userMapper.selectByEmail(email);
    }

    @Override
    public UserDO getUserByMobile(String mobile) {
        return userMapper.selectByMobile(mobile);
    }

    @Override
    public void validateUserExists(Long id) {
        if (getUser(id) == null) {
            throw new IllegalArgumentException("用户不存在");
        }
    }

    /**
     * 校验用户名的唯一性
     *
     * @param username 用户名
     * @param id       用户ID（更新时传入）
     */
    private void validateUsernameUnique(String username, Long id) {
        UserDO user = getUserByUsername(username);
        if (user == null) {
            return;
        }
        // 如果 id 为空，说明不用比较是否为相同 id 的用户
        if (id == null) {
            throw new IllegalArgumentException("用户名已存在");
        }
        if (!user.getId().equals(id)) {
            throw new IllegalArgumentException("用户名已存在");
        }
    }

}