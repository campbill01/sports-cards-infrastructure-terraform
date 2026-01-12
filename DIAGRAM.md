%%{init: {'theme':'base', 'themeVariables': { 'fontSize':'18px', 'fontFamily':'arial'}}}%%
graph TB
    subgraph "Multi-Region Deployment"
        subgraph "us-east-1 Region"
            subgraph "Production Environment"
                ALB1[Application Load Balancer]
                
                subgraph "ECS Cluster - API"
                    ASG1[Auto Scaling Group]
                    EC2_1[EC2 Instances]
                    API1[API Tasks]
                end
                
                subgraph "ECS Cluster - Workers"
                    ASG2[Auto Scaling Group - Data Sync]
                    ASG3[Auto Scaling Group - Image Processor]
                    EC2_2[EC2 Instances]
                    WORKER1[Data Sync Worker]
                    WORKER2[Image Processor Worker]
                end
                
                subgraph "Lambda Functions"
                    LAMBDA1[Card Processor]
                    LAMBDA2[User Service]
                end
                
                subgraph "Data Layer"
                    RDS1[(RDS PostgreSQL<br/>Multi-AZ Primary)]
                    RDS1_R1[(Read Replica 1)]
                    RDS1_R2[(Read Replica 2)]
                    RDS1_CR[(Cross-Region<br/>Read Replica)]
                end
                
                subgraph "Messaging"
                    SQS1[Notifications Queue]
                    SQS2[Data Sync Queue]
                    SQS3[Image Processor Queue]
                    DLQ1[Dead Letter Queues]
                end
                
                subgraph "Scheduling"
                    CW1[Daily Cleanup Rule]
                    CW2[Hourly Sync Rule]
                end
                
                subgraph "IAM"
                    IAM1[Users & Groups]
                    IAM2[Service Roles]
                    IAM3[Custom Policies]
                end
            end
            
            subgraph "Staging Environment"
                ALB_S[ALB]
                ECS_S[ECS API + Workers]
                RDS_S[(RDS Single-AZ)]
                SQS_S[SQS Queues]
                LAMBDA_S[Lambda Functions]
            end
            
            subgraph "Dev Environment"
                ALB_D[ALB]
                ECS_D[ECS API + Workers]
                RDS_D[(RDS Single-AZ)]
                SQS_D[SQS Queues]
                LAMBDA_D[Lambda Functions]
            end
        end
        
        subgraph "us-west-2 Region"
            subgraph "Production Environment DR"
                ALB2[Application Load Balancer]
                
                subgraph "ECS Cluster - API DR"
                    ASG4[Auto Scaling Group]
                    EC2_3[EC2 Instances]
                    API2[API Tasks]
                end
                
                subgraph "ECS Cluster - Workers DR"
                    ASG5[Auto Scaling Group - Data Sync]
                    ASG6[Auto Scaling Group - Image Processor]
                    EC2_4[EC2 Instances]
                    WORKER3[Data Sync Worker]
                    WORKER4[Image Processor Worker]
                end
                
                subgraph "Lambda Functions DR"
                    LAMBDA3[Card Processor]
                    LAMBDA4[User Service]
                end
                
                subgraph "Data Layer DR"
                    RDS2[(RDS PostgreSQL<br/>Multi-AZ Primary)]
                    RDS2_R1[(Read Replica 1)]
                    RDS2_R2[(Read Replica 2)]
                end
                
                subgraph "Messaging DR"
                    SQS4[Notifications Queue]
                    SQS5[Data Sync Queue]
                    SQS6[Image Processor Queue]
                    DLQ2[Dead Letter Queues]
                end
            end
        end
    end
    
    subgraph "Services (3 Total)"
        SVC1[card-catalog-api]
        SVC2[orders-ingestion]
        SVC3[manufacturing-orchestrator]
    end
    
    subgraph "State Management"
        subgraph "us-east-1 Backend"
            S3_1[(S3 State Bucket)]
            DDB_1[(DynamoDB Locks)]
        end
        
        subgraph "us-west-2 Backend"
            S3_2[(S3 State Bucket)]
            DDB_2[(DynamoDB Locks)]
        end
    end
    
    ALB1 --> API1
    API1 --> RDS1
    API1 --> RDS1_R1
    API1 --> RDS1_R2
    
    LAMBDA1 --> API1
    LAMBDA2 --> API1
    LAMBDA1 --> RDS1
    
    WORKER1 --> SQS2
    WORKER2 --> SQS3
    WORKER1 --> RDS1
    WORKER2 --> RDS1
    WORKER1 --> API1
    WORKER2 --> API1
    
    CW1 --> LAMBDA1
    CW2 --> SQS2
    
    SQS2 --> DLQ1
    SQS3 --> DLQ1
    
    RDS1 -.-> RDS1_CR
    RDS1_CR --> RDS2
    
    ALB2 --> API2
    API2 --> RDS2
    API2 --> RDS2_R1
    API2 --> RDS2_R2
    
    SVC1 --> S3_1
    SVC2 --> S3_1
    SVC3 --> S3_1
    SVC1 --> S3_2
    SVC2 --> S3_2
    SVC3 --> S3_2
    
    classDef default font-size:18px
    
    style RDS1 fill:#f9f,stroke:#333,stroke-width:4px
    style RDS2 fill:#f9f,stroke:#333,stroke-width:4px
    style RDS1_CR fill:#fcf,stroke:#333,stroke-width:2px
