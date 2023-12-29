# Bootstrap the Sentry environment
#
# Set up a consistent user, password, project and DSN access key
#

from sentry.utils.runner import configure
configure()

from sentry import roles
from sentry.models import (
    Organization,
    OrganizationMember,
    OrganizationMemberTeam,
    Project,
    ProjectKey,
    Team,
    User,
)

if User.objects.filter(username='docker').count() > 0 or Organization.get_default().name == 'Wispro':
    exit('Bootstrap done :+1:')

# user = User.objects.filter(username='docker')[0]
user = User(
    username = 'docker',
    email = 'docker@docker',
    is_superuser = True,
    is_staff = True,
    is_active = True,
)
user.set_password('docker')
user.save()

org = Organization.get_default()
org.name = 'Wispro'
org.save()

role = roles.get_top_dog().id

member = OrganizationMember.objects.create(
    organization=org,
    user=user,
    role=role,
)
team = Team.objects.filter(organization=org)[0]
OrganizationMemberTeam.objects.create(
    team=team,
    organizationmember=member,
)

project = Project.objects.all()[0]
project.name = 'Docker'
project.save()

# Force consistent keys for publishing to other dev containers
key = ProjectKey.objects.filter(project=project)[0]
key.public_key = 'ef9c130384880674ddefe3d6a4042a0f'
key.secret_key = 'efe3d6a4042a0f45b2af510f5e27ceac'
key.save()
