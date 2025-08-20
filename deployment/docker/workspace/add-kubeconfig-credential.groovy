import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*

def jenkins = Jenkins.getInstance()
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Read kubeconfig content
def kubeconfigContent = new File('/var/jenkins_home/.kube/config').text

// Create secret text credential for kubeconfig
def credential = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    'kubeconfig',
    'Kubernetes config for Kind cluster',
    kubeconfigContent
)

// Add credential to store
store.addCredentials(domain, credential)

// Save Jenkins configuration
jenkins.save()

println "Kubeconfig credential added successfully"