# frozen_string_literal: true

module Users
  class AliasesController < ApplicationController
    before_action :require_authentication
    before_action :set_alias, only: [:edit, :update, :destroy]

    def index
      @aliases = current_user.user_aliases
    end

    def new
      @alias = current_user.user_aliases.build
    end

    def create
      @alias = current_user.user_aliases.build(alias_params)

      if @alias.save
        redirect_to users_aliases_url, notice: I18n.t("aliases.created"), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @alias.update(alias_params)
        redirect_to users_aliases_url, notice: I18n.t("aliases.updated"), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @alias.destroy
      redirect_to users_aliases_url, notice: I18n.t("aliases.destroyed"), status: :see_other
    end

    private

    def set_alias
      @alias = current_user.user_aliases.find(params[:id])
    end

    def alias_params
      params.require(:user_alias).permit(:email)
    end
  end
end
