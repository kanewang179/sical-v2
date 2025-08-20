#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// 创建管理员用户
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// 设置授权策略
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// 禁用脚本安全
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// 保存配置
instance.save()

println "Jenkins初始化完成"
println "管理员用户: admin"
println "管理员密码: admin123"