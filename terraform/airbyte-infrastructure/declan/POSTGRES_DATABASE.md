# PostgreSQL RDS Database - Declan Environment

This document describes the PostgreSQL RDS database configured for the Declan environment.

## Database Configuration

- **Engine**: PostgreSQL 17.4
- **Instance Class**: db.t4g.micro (Free Tier eligible)
- **Storage**: 20 GB gp3 (Free Tier limit)
- **Database Name**: postgres
- **Username**: postgres
- **Password**: password
- **Port**: 5432
- **Multi-AZ**: No (Free Tier is single-AZ)
- **Backup Retention**: 7 days

## Deployment

### 1. Initialize Terraform (if not already done)

```bash
cd terraform/airbyte-infrastructure/declan
terraform init
```

### 2. Plan the changes

```bash
terraform plan
```

This will show you the new RDS resources that will be created:
- RDS instance
- DB subnet group
- Security group
- Security group rules
- CloudWatch log groups

### 3. Apply the configuration

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### 4. Get the database endpoint

After applying, get the connection information:

```bash
terraform output postgres_db_endpoint
terraform output postgres_db_address
terraform output postgres_connection_string
```

## Connecting to the Database

### From your EKS cluster (recommended)

Since the database is in a private subnet and allows connections from the EKS cluster security group, you can connect from any pod in your cluster:

```bash
# Deploy a test pod with psql
kubectl run postgres-client --rm -it --image=postgres:17 -- bash

# Inside the pod, connect to the database
psql -h <postgres_db_address> -U postgres -d postgres
# Password: password
```

Or set up a more permanent connection:

```yaml
# postgres-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-client
spec:
  containers:
  - name: postgres
    image: postgres:17
    command: ["sleep", "infinity"]
    env:
    - name: PGHOST
      value: "<postgres_db_address>"
    - name: PGUSER
      value: "postgres"
    - name: PGPASSWORD
      value: "password"
    - name: PGDATABASE
      value: "postgres"
```

Deploy and connect:

```bash
kubectl apply -f postgres-test-pod.yaml
kubectl exec -it postgres-client -- psql
```

### From your local machine (via bastion/jump host)

If you need to connect from outside the VPC, you'll need to:

1. **Option A**: Set up a bastion host in a public subnet
2. **Option B**: Use AWS Systems Manager Session Manager
3. **Option C**: Temporarily enable `publicly_accessible = true` (not recommended for production)

### Using Session Manager (recommended for local access)

```bash
# Start a port forwarding session through an EKS node
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<postgres_db_address>"],"portNumber":["5432"],"localPortNumber":["5432"]}'

# In another terminal, connect
psql -h localhost -U postgres -d postgres
```

## Connection Information

### Environment Variables for Applications

```bash
export POSTGRES_HOST="<postgres_db_address>"
export POSTGRES_PORT="5432"
export POSTGRES_DB="postgres"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="password"
```

### JDBC Connection String

```
jdbc:postgresql://<postgres_db_address>:5432/postgres?user=postgres&password=password
```

### Standard Connection String

```
postgresql://postgres:password@<postgres_db_address>:5432/postgres
```

## Security Configuration

### Network Access

- **VPC**: Same VPC as your EKS cluster
- **Subnets**: Private subnets (not directly accessible from internet)
- **Security Group**: Allows inbound PostgreSQL traffic (port 5432) from EKS cluster security group only
- **Publicly Accessible**: No

### Encryption

- **Storage Encryption**: Enabled (uses AWS managed KMS key)
- **In-Transit Encryption**: PostgreSQL supports SSL/TLS connections

To enforce SSL connections:

```sql
-- Connect to the database and run:
ALTER SYSTEM SET ssl = on;
SELECT pg_reload_conf();
```

## Monitoring

### CloudWatch Logs

The following logs are exported to CloudWatch:
- PostgreSQL logs
- Upgrade logs

View logs:

```bash
aws logs tail /aws/rds/instance/airbyte-eks-declan-postgres/postgresql --follow
```

### Basic Monitoring

Free tier includes basic CloudWatch metrics (5-minute intervals):
- CPU utilization
- Database connections
- Disk I/O
- Network traffic

View in AWS Console: RDS → Databases → airbyte-eks-declan-postgres → Monitoring

## Maintenance

### Backup Configuration

- **Automated Backups**: Enabled
- **Retention Period**: 7 days
- **Backup Window**: Not specified (AWS chooses automatically)
- **Final Snapshot**: Disabled (for dev/testing)

### Maintenance Window

- **Window**: Monday 04:00-05:00 UTC
- **Auto Minor Version Upgrade**: Enabled

### Manual Snapshot

Create a manual snapshot:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier airbyte-eks-declan-postgres \
  --db-snapshot-identifier airbyte-eks-declan-postgres-manual-$(date +%Y%m%d)
```

## Database Management

### Create Additional Databases

```sql
CREATE DATABASE airbyte;
CREATE DATABASE myapp;
```

### Create Additional Users

```sql
CREATE USER airbyte WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE airbyte TO airbyte;
```

### Check Database Size

```sql
SELECT 
  pg_database.datname,
  pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```

### Check Connections

```sql
SELECT 
  datname,
  count(*) as connections
FROM pg_stat_activity
GROUP BY datname;
```

## Troubleshooting

### Cannot Connect from EKS

1. **Verify security group rules:**
   ```bash
   aws ec2 describe-security-groups \
     --group-ids $(terraform output -raw postgres_db_security_group_id)
   ```

2. **Verify the database is available:**
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier airbyte-eks-declan-postgres \
     --query 'DBInstances[0].DBInstanceStatus'
   ```

3. **Test DNS resolution from a pod:**
   ```bash
   kubectl run test --rm -it --image=busybox -- nslookup <postgres_db_address>
   ```

### Performance Issues

Free tier limitations:
- 20 GB storage maximum
- db.t4g.micro: 2 vCPUs, 1 GB RAM
- Basic monitoring only

For better performance, consider upgrading:
- Instance class: db.t4g.small or larger
- Enable Performance Insights
- Enable Enhanced Monitoring

### Storage Full

Check current storage usage:

```sql
SELECT 
  pg_size_pretty(pg_database_size(current_database())) as db_size,
  pg_size_pretty(pg_total_relation_size('pg_catalog.pg_class')) as catalog_size;
```

To increase storage (requires instance modification):

```hcl
# In main.tf, change:
allocated_storage = 30  # or more

# Then apply:
terraform apply
```

## Cost Considerations

### Free Tier Eligibility

AWS RDS Free Tier includes:
- 750 hours per month of db.t3.micro or db.t4g.micro
- 20 GB of General Purpose (SSD) storage
- 20 GB of backup storage

**Current Configuration**: This setup is free tier eligible!

### Beyond Free Tier

If you exceed free tier limits, costs will apply:
- Additional storage: ~$0.115/GB-month (gp3)
- Backup storage over 20 GB: ~$0.095/GB-month
- Data transfer: varies by region

## Production Recommendations

⚠️ **This configuration is for development/testing. For production, consider:**

1. **Security:**
   - Use AWS Secrets Manager for password management
   - Enable deletion protection
   - Create parameter group with security settings
   - Enable SSL/TLS enforcement

2. **High Availability:**
   - Enable Multi-AZ deployment
   - Set up read replicas if needed
   - Configure automated failover

3. **Performance:**
   - Upgrade to db.r6g.large or larger
   - Increase allocated storage
   - Enable Performance Insights
   - Enable Enhanced Monitoring (60-second intervals)

4. **Backup & Recovery:**
   - Set skip_final_snapshot = false
   - Increase backup retention to 14-30 days
   - Set up AWS Backup for additional protection

5. **Monitoring:**
   - Set up CloudWatch alarms
   - Enable Performance Insights
   - Configure SNS notifications

## Terraform Commands Reference

```bash
# View current state
terraform show

# Get specific output
terraform output postgres_db_endpoint

# Get all outputs
terraform output

# Refresh state
terraform refresh

# Destroy the database (WARNING: destructive!)
terraform destroy -target=module.postgres_db

# Modify the database
# 1. Edit main.tf
# 2. Run:
terraform plan
terraform apply
```

## Additional Resources

- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [AWS RDS PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [AWS RDS Free Tier](https://aws.amazon.com/rds/free/)
- [RDS Module Documentation](../../modules/rds/README.md)

