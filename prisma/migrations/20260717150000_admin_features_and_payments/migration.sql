-- CreateEnum
CREATE TYPE "AppealType" AS ENUM ('SUSPENSION', 'VERIFICATION', 'PAYOUT_HOLD');

-- CreateEnum
CREATE TYPE "SkillStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "BadgeType" AS ENUM ('VERIFIED', 'TOP_ARTISAN');

-- CreateEnum
CREATE TYPE "BadgeStatus" AS ENUM ('PENDING', 'ACTIVE', 'REVOKED', 'HELD', 'REJECTED');

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('PAYMENT', 'PAYOUT', 'REFUND', 'DEPOSIT', 'WITHDRAWAL', 'FEE');

-- CreateEnum
CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'STUCK', 'REVERSED');

-- CreateEnum
CREATE TYPE "RefundStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- CreateEnum
CREATE TYPE "JobStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "DisputeState" AS ENUM ('NONE', 'OPEN', 'RESOLVED');

-- CreateEnum
CREATE TYPE "EscrowStatus" AS ENUM ('HELD', 'RELEASED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "ComplaintStatus" AS ENUM ('NEW', 'IN_REVIEW', 'ESCALATED', 'RESOLVED', 'CLOSED_INVALID');

-- CreateEnum
CREATE TYPE "DisputeStatus" AS ENUM ('OPEN', 'RESOLVED');

-- CreateEnum
CREATE TYPE "PlanInterval" AS ENUM ('MONTHLY', 'QUARTERLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('ACTIVE', 'CANCELLED', 'EXPIRED', 'PAST_DUE');

-- CreateEnum
CREATE TYPE "TemplateType" AS ENUM ('ADMIN', 'SYSTEM');

-- CreateEnum
CREATE TYPE "MessageDeliveryStatus" AS ENUM ('QUEUED', 'SENT', 'DELIVERED', 'READ', 'BOUNCED', 'FAILED');

-- CreateEnum
CREATE TYPE "PaymentGatewayStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "SupportTicketStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED');

-- AlterEnum
ALTER TYPE "ArtisanStatus" ADD VALUE 'ACTIVE';

-- AlterEnum
BEGIN;
CREATE TYPE "ServiceRequestStatus_new" AS ENUM ('OPEN', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
ALTER TABLE "ServiceRequest" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "ServiceRequest" ALTER COLUMN "status" TYPE "ServiceRequestStatus_new" USING ("status"::text::"ServiceRequestStatus_new");
ALTER TYPE "ServiceRequestStatus" RENAME TO "ServiceRequestStatus_old";
ALTER TYPE "ServiceRequestStatus_new" RENAME TO "ServiceRequestStatus";
DROP TYPE "ServiceRequestStatus_old";
ALTER TABLE "ServiceRequest" ALTER COLUMN "status" SET DEFAULT 'OPEN';
COMMIT;

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "AppealStatus" ADD VALUE 'IN_REVIEW';
ALTER TYPE "AppealStatus" ADD VALUE 'DENIED';

-- DropForeignKey
ALTER TABLE "ServiceRequest" DROP CONSTRAINT "ServiceRequest_artisanId_fkey";

-- DropIndex
DROP INDEX "ServiceRequest_state_skillRequired_status_idx";

-- DropIndex
DROP INDEX "ServiceRequest_artisanId_idx";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "flagReason" TEXT,
ADD COLUMN     "flagged" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "phone" TEXT,
ADD COLUMN     "profilePicture" TEXT,
ADD COLUMN     "profileVisible" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "ArtisanProfile" ADD COLUMN     "bio" TEXT,
ADD COLUMN     "completedJobs" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "location" TEXT,
ADD COLUMN     "profilePicture" TEXT,
ADD COLUMN     "rating" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "verificationDocuments" TEXT[],
ADD COLUMN     "yearsOfExperience" INTEGER;

-- AlterTable
ALTER TABLE "Skill" ADD COLUMN     "categoryRefId" UUID,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "description" TEXT,
ADD COLUMN     "icon" TEXT,
ADD COLUMN     "status" "SkillStatus" NOT NULL DEFAULT 'ACTIVE',
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "ServiceRequest" DROP COLUMN "artisanId",
DROP COLUMN "skillRequired",
ADD COLUMN     "acceptedArtisanId" UUID,
ADD COLUMN     "category" TEXT NOT NULL,
ADD COLUMN     "disputeReason" TEXT,
ADD COLUMN     "disputeState" "DisputeState" NOT NULL DEFAULT 'NONE',
ADD COLUMN     "jobStatus" "JobStatus" NOT NULL DEFAULT 'PENDING',
ADD COLUMN     "location" TEXT NOT NULL,
ADD COLUMN     "preferredSkills" TEXT[],
ADD COLUMN     "urgency2" TEXT,
ALTER COLUMN "title" DROP NOT NULL,
ALTER COLUMN "state" DROP NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'OPEN';

-- AlterTable
ALTER TABLE "Appeal" ADD COLUMN     "adminNote" TEXT,
ADD COLUMN     "decidedAt" TIMESTAMP(3),
ADD COLUMN     "escalated" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "escalationNote" TEXT,
ADD COLUMN     "responseText" TEXT,
ADD COLUMN     "type" "AppealType" NOT NULL DEFAULT 'SUSPENSION',
ADD COLUMN     "urgent" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "SkillCategory" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SkillCategory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Badge" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "type" "BadgeType" NOT NULL,
    "status" "BadgeStatus" NOT NULL DEFAULT 'PENDING',
    "note" TEXT,
    "reason" TEXT,
    "awardedAt" TIMESTAMP(3),
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Badge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Transaction" (
    "id" UUID NOT NULL,
    "reference" TEXT NOT NULL,
    "userId" UUID,
    "jobId" UUID,
    "type" "TransactionType" NOT NULL,
    "status" "TransactionStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'NGN',
    "platformFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "gateway" TEXT,
    "description" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Refund" (
    "id" UUID NOT NULL,
    "transactionId" UUID NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "RefundStatus" NOT NULL DEFAULT 'PENDING',
    "idempotencyKey" TEXT NOT NULL,
    "gatewayRef" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Refund_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Escrow" (
    "id" UUID NOT NULL,
    "jobId" UUID NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" "EscrowStatus" NOT NULL DEFAULT 'HELD',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Escrow_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Milestone" (
    "id" UUID NOT NULL,
    "jobId" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "amount" DOUBLE PRECISION,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "dueDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Milestone_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DisputeNote" (
    "id" UUID NOT NULL,
    "jobId" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "authorId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DisputeNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Complaint" (
    "id" UUID NOT NULL,
    "filedById" UUID,
    "againstId" UUID,
    "jobId" UUID,
    "subject" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "ComplaintStatus" NOT NULL DEFAULT 'NEW',
    "escalated" BOOLEAN NOT NULL DEFAULT false,
    "outcome" TEXT,
    "resolutionNotes" TEXT,
    "closeReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Complaint_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ComplaintNote" (
    "id" UUID NOT NULL,
    "complaintId" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "authorId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ComplaintNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Dispute" (
    "id" UUID NOT NULL,
    "complaintId" UUID NOT NULL,
    "status" "DisputeStatus" NOT NULL DEFAULT 'OPEN',
    "frozenAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "outcome" TEXT,
    "resolvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Dispute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DisputeEvidence" (
    "id" UUID NOT NULL,
    "disputeId" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "url" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DisputeEvidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DisputeNoteEntry" (
    "id" UUID NOT NULL,
    "disputeId" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "authorId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DisputeNoteEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminNote" (
    "id" UUID NOT NULL,
    "subjectId" UUID NOT NULL,
    "authorId" UUID,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdminNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ActivityEvent" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ActivityEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" UUID NOT NULL,
    "authorId" UUID,
    "subjectId" UUID,
    "jobId" UUID,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Post" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "caption" TEXT,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubscriptionPlan" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "price" DOUBLE PRECISION NOT NULL,
    "interval" "PlanInterval" NOT NULL DEFAULT 'MONTHLY',
    "features" TEXT[],
    "jobLimit" INTEGER,
    "archived" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SubscriptionPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subscription" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "planId" UUID NOT NULL,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubscriptionNote" (
    "id" UUID NOT NULL,
    "subscriptionId" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "authorId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SubscriptionNote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MessageTemplate" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "subject" TEXT,
    "body" TEXT NOT NULL,
    "channels" TEXT[],
    "type" "TemplateType" NOT NULL DEFAULT 'ADMIN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MessageTemplate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MessageLog" (
    "id" UUID NOT NULL,
    "channel" TEXT NOT NULL,
    "audience" TEXT,
    "subject" TEXT,
    "body" TEXT,
    "recipients" INTEGER NOT NULL DEFAULT 0,
    "status" "MessageDeliveryStatus" NOT NULL DEFAULT 'QUEUED',
    "isTest" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MessageLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Setting" (
    "id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Setting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentGateway" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "apiKey" TEXT,
    "secretKey" TEXT,
    "merchantEmail" TEXT,
    "testMode" BOOLEAN NOT NULL DEFAULT true,
    "status" "PaymentGatewayStatus" NOT NULL DEFAULT 'INACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentGateway_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminSession" (
    "id" UUID NOT NULL,
    "adminId" UUID NOT NULL,
    "device" TEXT,
    "ip" TEXT,
    "lastActive" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdminSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FirewallIp" (
    "id" UUID NOT NULL,
    "ip" TEXT NOT NULL,
    "label" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FirewallIp_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" UUID NOT NULL,
    "actorId" UUID,
    "action" TEXT NOT NULL,
    "entity" TEXT,
    "entityId" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Faq" (
    "id" UUID NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "published" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Faq_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KnowledgeArticle" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT,
    "content" TEXT NOT NULL,
    "category" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KnowledgeArticle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SupportTicket" (
    "id" UUID NOT NULL,
    "userId" UUID,
    "subject" TEXT NOT NULL,
    "priority" TEXT,
    "status" "SupportTicketStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SupportTicket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SupportMessage" (
    "id" UUID NOT NULL,
    "ticketId" UUID NOT NULL,
    "sender" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SupportMessage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SkillCategory_name_key" ON "SkillCategory"("name");

-- CreateIndex
CREATE INDEX "SkillCategory_name_idx" ON "SkillCategory"("name");

-- CreateIndex
CREATE INDEX "Badge_userId_idx" ON "Badge"("userId");

-- CreateIndex
CREATE INDEX "Badge_status_idx" ON "Badge"("status");

-- CreateIndex
CREATE INDEX "Badge_type_idx" ON "Badge"("type");

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_reference_key" ON "Transaction"("reference");

-- CreateIndex
CREATE INDEX "Transaction_status_idx" ON "Transaction"("status");

-- CreateIndex
CREATE INDEX "Transaction_type_idx" ON "Transaction"("type");

-- CreateIndex
CREATE INDEX "Transaction_userId_idx" ON "Transaction"("userId");

-- CreateIndex
CREATE INDEX "Transaction_reference_idx" ON "Transaction"("reference");

-- CreateIndex
CREATE UNIQUE INDEX "Refund_idempotencyKey_key" ON "Refund"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Refund_transactionId_idx" ON "Refund"("transactionId");

-- CreateIndex
CREATE INDEX "Refund_status_idx" ON "Refund"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Escrow_jobId_key" ON "Escrow"("jobId");

-- CreateIndex
CREATE INDEX "Escrow_status_idx" ON "Escrow"("status");

-- CreateIndex
CREATE INDEX "Milestone_jobId_idx" ON "Milestone"("jobId");

-- CreateIndex
CREATE INDEX "DisputeNote_jobId_idx" ON "DisputeNote"("jobId");

-- CreateIndex
CREATE INDEX "Complaint_status_idx" ON "Complaint"("status");

-- CreateIndex
CREATE INDEX "Complaint_filedById_idx" ON "Complaint"("filedById");

-- CreateIndex
CREATE INDEX "Complaint_againstId_idx" ON "Complaint"("againstId");

-- CreateIndex
CREATE INDEX "ComplaintNote_complaintId_idx" ON "ComplaintNote"("complaintId");

-- CreateIndex
CREATE UNIQUE INDEX "Dispute_complaintId_key" ON "Dispute"("complaintId");

-- CreateIndex
CREATE INDEX "Dispute_status_idx" ON "Dispute"("status");

-- CreateIndex
CREATE INDEX "DisputeEvidence_disputeId_idx" ON "DisputeEvidence"("disputeId");

-- CreateIndex
CREATE INDEX "DisputeNoteEntry_disputeId_idx" ON "DisputeNoteEntry"("disputeId");

-- CreateIndex
CREATE INDEX "AdminNote_subjectId_idx" ON "AdminNote"("subjectId");

-- CreateIndex
CREATE INDEX "ActivityEvent_userId_idx" ON "ActivityEvent"("userId");

-- CreateIndex
CREATE INDEX "Review_authorId_idx" ON "Review"("authorId");

-- CreateIndex
CREATE INDEX "Review_subjectId_idx" ON "Review"("subjectId");

-- CreateIndex
CREATE INDEX "Post_userId_idx" ON "Post"("userId");

-- CreateIndex
CREATE INDEX "SubscriptionPlan_archived_idx" ON "SubscriptionPlan"("archived");

-- CreateIndex
CREATE INDEX "Subscription_userId_idx" ON "Subscription"("userId");

-- CreateIndex
CREATE INDEX "Subscription_planId_idx" ON "Subscription"("planId");

-- CreateIndex
CREATE INDEX "Subscription_status_idx" ON "Subscription"("status");

-- CreateIndex
CREATE INDEX "SubscriptionNote_subscriptionId_idx" ON "SubscriptionNote"("subscriptionId");

-- CreateIndex
CREATE INDEX "MessageTemplate_type_idx" ON "MessageTemplate"("type");

-- CreateIndex
CREATE INDEX "MessageLog_status_idx" ON "MessageLog"("status");

-- CreateIndex
CREATE INDEX "MessageLog_channel_idx" ON "MessageLog"("channel");

-- CreateIndex
CREATE UNIQUE INDEX "Setting_key_key" ON "Setting"("key");

-- CreateIndex
CREATE INDEX "Setting_key_idx" ON "Setting"("key");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGateway_name_key" ON "PaymentGateway"("name");

-- CreateIndex
CREATE INDEX "AdminSession_adminId_idx" ON "AdminSession"("adminId");

-- CreateIndex
CREATE UNIQUE INDEX "FirewallIp_ip_key" ON "FirewallIp"("ip");

-- CreateIndex
CREATE INDEX "AuditLog_actorId_idx" ON "AuditLog"("actorId");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");

-- CreateIndex
CREATE INDEX "Faq_published_idx" ON "Faq"("published");

-- CreateIndex
CREATE INDEX "KnowledgeArticle_category_idx" ON "KnowledgeArticle"("category");

-- CreateIndex
CREATE INDEX "SupportTicket_status_idx" ON "SupportTicket"("status");

-- CreateIndex
CREATE INDEX "SupportTicket_userId_idx" ON "SupportTicket"("userId");

-- CreateIndex
CREATE INDEX "SupportMessage_ticketId_idx" ON "SupportMessage"("ticketId");

-- CreateIndex
CREATE INDEX "Skill_status_idx" ON "Skill"("status");

-- CreateIndex
CREATE INDEX "ServiceRequest_location_category_status_idx" ON "ServiceRequest"("location", "category", "status");

-- CreateIndex
CREATE INDEX "ServiceRequest_acceptedArtisanId_idx" ON "ServiceRequest"("acceptedArtisanId");

-- CreateIndex
CREATE INDEX "ServiceRequest_jobStatus_idx" ON "ServiceRequest"("jobStatus");

-- CreateIndex
CREATE INDEX "Appeal_type_idx" ON "Appeal"("type");

-- AddForeignKey
ALTER TABLE "Skill" ADD CONSTRAINT "Skill_categoryRefId_fkey" FOREIGN KEY ("categoryRefId") REFERENCES "SkillCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceRequest" ADD CONSTRAINT "ServiceRequest_acceptedArtisanId_fkey" FOREIGN KEY ("acceptedArtisanId") REFERENCES "ArtisanProfile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Badge" ADD CONSTRAINT "Badge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "ServiceRequest"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Refund" ADD CONSTRAINT "Refund_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Escrow" ADD CONSTRAINT "Escrow_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "ServiceRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Milestone" ADD CONSTRAINT "Milestone_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "ServiceRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DisputeNote" ADD CONSTRAINT "DisputeNote_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "ServiceRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Complaint" ADD CONSTRAINT "Complaint_filedById_fkey" FOREIGN KEY ("filedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Complaint" ADD CONSTRAINT "Complaint_againstId_fkey" FOREIGN KEY ("againstId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ComplaintNote" ADD CONSTRAINT "ComplaintNote_complaintId_fkey" FOREIGN KEY ("complaintId") REFERENCES "Complaint"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dispute" ADD CONSTRAINT "Dispute_complaintId_fkey" FOREIGN KEY ("complaintId") REFERENCES "Complaint"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DisputeEvidence" ADD CONSTRAINT "DisputeEvidence_disputeId_fkey" FOREIGN KEY ("disputeId") REFERENCES "Dispute"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DisputeNoteEntry" ADD CONSTRAINT "DisputeNoteEntry_disputeId_fkey" FOREIGN KEY ("disputeId") REFERENCES "Dispute"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdminNote" ADD CONSTRAINT "AdminNote_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ActivityEvent" ADD CONSTRAINT "ActivityEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_planId_fkey" FOREIGN KEY ("planId") REFERENCES "SubscriptionPlan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SubscriptionNote" ADD CONSTRAINT "SubscriptionNote_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupportTicket" ADD CONSTRAINT "SupportTicket_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SupportMessage" ADD CONSTRAINT "SupportMessage_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "SupportTicket"("id") ON DELETE CASCADE ON UPDATE CASCADE;

