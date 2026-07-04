"use client";

import type { ReactNode } from "react";
import { AlertTriangle, Loader2 } from "lucide-react";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "./alert-dialog";
import { cn } from "./utils";

type ConfirmDialogTone = "danger" | "warning" | "default";

interface ConfirmActionDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: ReactNode;
  children?: ReactNode;
  onConfirm: () => void;
  loading?: boolean;
  loadingLabel?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  dir?: "rtl" | "ltr";
  tone?: ConfirmDialogTone;
  showIcon?: boolean;
  icon?: ReactNode;
  contentClassName?: string;
  confirmButtonClassName?: string;
}

const toneStyles: Record<
  ConfirmDialogTone,
  { header: string; icon: string; confirmButton: string }
> = {
  danger: {
    header: "border-b from-red-50 to-white",
    icon: "bg-red-100 text-red-600",
    confirmButton: "bg-red-600 hover:bg-red-700 focus-visible:ring-red-600",
  },
  warning: {
    header: "border-b from-amber-50 to-white",
    icon: "bg-amber-100 text-amber-600",
    confirmButton: "bg-amber-600 hover:bg-amber-700 focus-visible:ring-amber-600",
  },
  default: {
    header: "border-b from-gray-50 to-white",
    icon: "bg-gray-100 text-gray-600",
    confirmButton: "",
  },
};

function ConfirmActionDialog({
  open,
  onOpenChange,
  title,
  description,
  children,
  onConfirm,
  loading = false,
  loadingLabel = "جارٍ التنفيذ...",
  confirmLabel = "تأكيد",
  cancelLabel = "إلغاء",
  dir = "rtl",
  tone = "danger",
  showIcon = true,
  icon,
  contentClassName,
  confirmButtonClassName,
}: ConfirmActionDialogProps) {
  const styles = toneStyles[tone];
  const isRtl = dir === "rtl";
  const textAlignClass = isRtl ? "text-right" : "text-left";
  const gradientDirection = isRtl ? "bg-gradient-to-l" : "bg-gradient-to-r";

  return (
    <AlertDialog
      open={open}
      onOpenChange={(nextOpen) => {
        if (loading) return;
        onOpenChange(nextOpen);
      }}
    >
      <AlertDialogContent
        className={cn(
          "w-[calc(100vw-1.25rem)] sm:w-[min(92vw,34rem)] md:max-w-lg max-h-[92dvh] rounded-2xl p-0 overflow-hidden",
          textAlignClass,
          contentClassName,
        )}
        dir={dir}
      >
        <div className={cn(styles.header, gradientDirection, "p-4 sm:p-5")}>
          <AlertDialogHeader
            className={cn(
              textAlignClass,
              isRtl ? "items-end" : "items-start",
            )}
          >
            <div className="flex items-start gap-3">
              {showIcon && (
                <div
                  className={cn(
                    "mt-0.5 flex h-9 w-9 sm:h-10 sm:w-10 shrink-0 items-center justify-center rounded-full",
                    styles.icon,
                  )}
                >
                  {icon ?? <AlertTriangle className="h-5 w-5" />}
                </div>
              )}

              <div>
                <AlertDialogTitle className="text-base sm:text-lg md:text-xl font-bold text-gray-900">
                  {title}
                </AlertDialogTitle>
                {description && (
                  <AlertDialogDescription className="mt-1 text-sm leading-6 text-gray-600">
                    {description}
                  </AlertDialogDescription>
                )}
              </div>
            </div>
          </AlertDialogHeader>
        </div>

        <div className={cn("p-4 sm:p-5 space-y-4", textAlignClass)}>
          {children}

          <AlertDialogFooter
            className={cn(
              "flex-col-reverse gap-2 sm:flex-row",
              isRtl ? "sm:justify-start" : "sm:justify-end",
              "[&>button]:w-full sm:[&>button]:w-auto",
            )}
          >
            <AlertDialogCancel disabled={loading}>{cancelLabel}</AlertDialogCancel>
            <AlertDialogAction
              disabled={loading}
              onClick={(e) => {
                e.preventDefault();
                onConfirm();
              }}
              className={cn(styles.confirmButton, confirmButtonClassName)}
            >
              {loading ? (
                <span className="inline-flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {loadingLabel}
                </span>
              ) : (
                confirmLabel
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </div>
      </AlertDialogContent>
    </AlertDialog>
  );
}

export { ConfirmActionDialog };
