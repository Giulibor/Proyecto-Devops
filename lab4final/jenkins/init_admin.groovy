import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
if (hudsonRealm.getAllUsers().isEmpty()) {
    hudsonRealm.createAccount("admin", "admin123")
    instance.setSecurityRealm(hudsonRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)

    instance.save()
    println("Admin user 'admin' created with password 'admin'")
} else {
    println("Admin user already exists, skipping init_admin.groovy")
}