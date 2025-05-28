package org.qingshu.server.dal.mysql;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.qingshu.server.dal.dataobject.UserDO;

/**
 * 用户 Mapper
 *
 * @author vvnocode
 */
@Mapper
public interface UserMapper extends BaseMapper<UserDO> {

    /**
     * 根据用户名查询用户
     *
     * @param username 用户名
     * @return 用户信息
     */
    default UserDO selectByUsername(String username) {
        return selectOne(new LambdaQueryWrapper<UserDO>()
                .eq(UserDO::getUsername, username));
    }

    /**
     * 根据邮箱查询用户
     *
     * @param email 邮箱
     * @return 用户信息
     */
    default UserDO selectByEmail(String email) {
        return selectOne(new LambdaQueryWrapper<UserDO>()
                .eq(UserDO::getEmail, email));
    }

    /**
     * 根据手机号查询用户
     *
     * @param mobile 手机号
     * @return 用户信息
     */
    default UserDO selectByMobile(String mobile) {
        return selectOne(new LambdaQueryWrapper<UserDO>()
                .eq(UserDO::getMobile, mobile));
    }

}