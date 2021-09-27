/*
  Warnings:

  - The values [organisation] on the enum `beneficiary_type` will be removed. If these variants are still used in the database, this will fail.
  - The `currency` column on the `campaigns` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - A unique constraint covering the columns `[personal_number]` on the table `people` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "currency" AS ENUM ('BGN', 'EUR', 'USD');

-- CreateEnum
CREATE TYPE "transaction_type" AS ENUM ('donation');

-- CreateEnum
CREATE TYPE "transfer_type" AS ENUM ('withdraw', 'relocation');

-- CreateEnum
CREATE TYPE "expense_type" AS ENUM ('none', 'internal', 'operating', 'administrative', 'medical', 'services', 'groceries', 'transport', 'accommodation', 'shipping', 'utility', 'rental', 'legal', 'bank', 'advertising', 'other');

-- CreateEnum
CREATE TYPE "payment_provider" AS ENUM ('none', 'stripe', 'paypal', 'epay', 'bank', 'cash');

-- CreateEnum
CREATE TYPE "subscription_status" AS ENUM ('trialing', 'active', 'canceled', 'incomplete', 'incompleteExpired', 'pastDue', 'unpaid');

-- CreateEnum
CREATE TYPE "vault_type" AS ENUM ('personal', 'campaign');

-- CreateEnum
CREATE TYPE "document_type" AS ENUM ('invoice', 'receipt', 'medical_record', 'other');

-- CreateEnum
CREATE TYPE "transaction_status" AS ENUM ('initial', 'invalid', 'incomplete', 'declined', 'waiting', 'cancelled', 'succeeded', 'deleted', 'refund', 'paymentRequested');

-- CreateEnum
CREATE TYPE "payout_type" AS ENUM ('cash', 'bank');

-- CreateEnum
CREATE TYPE "payout_status" AS ENUM ('initial', 'invalid', 'incomplete', 'declined', 'cancelled', 'succeeded');

-- CreateEnum
CREATE TYPE "account_holder_type" AS ENUM ('individual', 'company');

-- CreateEnum
CREATE TYPE "bank_account_status" AS ENUM ('new', 'validated', 'verified', 'verification_failed', 'errored');

-- AlterEnum
BEGIN;
CREATE TYPE "beneficiary_type_new" AS ENUM ('individual', 'company');
ALTER TABLE "beneficiaries" ALTER COLUMN "type" TYPE "beneficiary_type_new" USING ("type"::text::"beneficiary_type_new");
ALTER TYPE "beneficiary_type" RENAME TO "beneficiary_type_old";
ALTER TYPE "beneficiary_type_new" RENAME TO "beneficiary_type";
DROP TYPE "beneficiary_type_old";
COMMIT;

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "person_relation" ADD VALUE 'myself';
ALTER TYPE "person_relation" ADD VALUE 'myorg';

-- DropForeignKey
ALTER TABLE "beneficiaries" DROP CONSTRAINT "beneficiaries_person_id_fkey";

-- AlterTable
ALTER TABLE "beneficiaries" ADD COLUMN     "company_id" UUID,
ALTER COLUMN "person_id" DROP NOT NULL;

-- AlterTable
ALTER TABLE "campaigns" ADD COLUMN     "vault_id" UUID,
DROP COLUMN "currency",
ADD COLUMN     "currency" "currency" DEFAULT E'BGN';

-- AlterTable
ALTER TABLE "coordinators" ADD COLUMN     "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "updated_at" TIMESTAMPTZ(6);

-- AlterTable
ALTER TABLE "people" ADD COLUMN     "personal_number" TEXT,
ADD COLUMN     "vault_id" UUID,
ALTER COLUMN "address" SET DATA TYPE VARCHAR(100);

-- DropEnum
DROP TYPE "Currency";

-- CreateTable
CREATE TABLE "companies" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "company_name" VARCHAR(100) NOT NULL,
    "companyNumber" TEXT NOT NULL,
    "legal_person_name" TEXT,
    "country_code" CITEXT,
    "city_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "benefactors" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "person_id" UUID NOT NULL,
    "customer_id" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "benefactors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vaults" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "vault_type" NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL DEFAULT 0.0,
    "currency" "currency" NOT NULL DEFAULT E'BGN',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "vaults_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "transaction_type" NOT NULL,
    "status" "transaction_status" NOT NULL DEFAULT E'initial',
    "provider" "payment_provider" NOT NULL DEFAULT E'none',
    "target_vault_id" UUID NOT NULL,
    "customer_id" TEXT NOT NULL,
    "payment_intent_id" TEXT NOT NULL,
    "payment_method_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "status" "subscription_status" NOT NULL,
    "vault_id" UUID NOT NULL,
    "person_id" UUID NOT NULL,
    "subscription_id" TEXT NOT NULL,
    "customer_id" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transfers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "transfer_type" NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "reason" VARCHAR(100) NOT NULL,
    "source_vault_id" UUID NOT NULL,
    "target_vault_id" UUID NOT NULL,
    "target_date" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "transfers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "withdraws" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "payout_type" NOT NULL,
    "status" "payout_status" NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "vault_id" UUID NOT NULL,
    "document_id" UUID,
    "target_date" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "withdraws_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_accounts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "status" "bank_account_status" NOT NULL,
    "last4" TEXT NOT NULL,
    "account_holder_name" TEXT NOT NULL,
    "account_holder_type" "account_holder_type" NOT NULL,
    "bank_name" TEXT,
    "fingerprint" TEXT,
    "withdraw_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6),

    CONSTRAINT "bank_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expenses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "expense_type" NOT NULL,
    "vault_id" UUID NOT NULL,
    "document_id" UUID,

    CONSTRAINT "expenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "type" "document_type" NOT NULL,
    "name" TEXT NOT NULL,
    "filetype" TEXT,
    "description" TEXT,
    "source_url" TEXT NOT NULL,
    "owner_id" UUID NOT NULL,

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "companies_companyNumber_key" ON "companies"("companyNumber");

-- CreateIndex
CREATE UNIQUE INDEX "benefactors_customer_id_key" ON "benefactors"("customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_customer_id_key" ON "subscriptions"("customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "people_personal_number_key" ON "people"("personal_number");

-- AddForeignKey
ALTER TABLE "people" ADD CONSTRAINT "people_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "vaults"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "benefactors" ADD CONSTRAINT "benefactors_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "people"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "beneficiaries" ADD CONSTRAINT "beneficiaries_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "people"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "beneficiaries" ADD CONSTRAINT "beneficiaries_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "vaults"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_target_vault_id_fkey" FOREIGN KEY ("target_vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "people"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transfers" ADD CONSTRAINT "transfers_source_vault_id_fkey" FOREIGN KEY ("source_vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transfers" ADD CONSTRAINT "transfers_target_vault_id_fkey" FOREIGN KEY ("target_vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "withdraws" ADD CONSTRAINT "withdraws_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_accounts" ADD CONSTRAINT "bank_accounts_withdraw_id_fkey" FOREIGN KEY ("withdraw_id") REFERENCES "withdraws"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "vaults"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "people"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
