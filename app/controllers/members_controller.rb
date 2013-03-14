class MembersController < ApplicationController
  before_filter :find_group, only: [:index, :show, :update, :destroy, :join, :leave, :request_to_join, :delete_request]
  before_filter :login_required, only: [:join, :update, :destroy, :request_to_join, :delete_request]
  before_filter :member_only, only: [:leave]
  before_filter :group_member_only, only: [:index, :show]
  before_filter :find_user_group, only: [:update, :destroy]
  before_filter :manager_only, only: [:update, :destroy]
  before_filter :owner_only, only: :destroy

  def index
    @events = @group.events
  end

  def show
    @current_user = @group.users.find(params[:id])
    @user_group = @current_user.user_group(@group)

    time = @user_group.created_at
    if oldst = @current_user.user_events.minimum(:created_at)
      time = oldst if oldst < time
    end
    @events = @group.events.where('created_at >= ?', time)
  end

  def update #TODO: viewが整理されないとリファクタリング辛い
    if @user_group.update_attributes(user_group_params)
      redirect_to group_members_url(group_id: @group.id), notice: 'Role was successfully updateed.'
    else
      redirect_to group_members_url(group_id: @group.id)
    end
  end

  def destroy
    @user_group.destroy
    redirect_to group_members_url(@group.id), notice: 'Remeved member.'
  end

  def leave
    @group.users.delete(@user)
    redirect_to @group, notice: 'Left.'
  end

  def join
    unless @group.public?
      redirect_to group_url(@group.id), notice: 'Not joined.'
      return
    end

    if @group.member?(@user)
      redirect_to group_url(@group.id), notice: 'You already are a member of this group.'
    else
      @group.users << @user
      redirect_to group_url(@group.id), notice: 'Joined.'
    end
  end

  def request_to_join
    if @group.public?
      redirect_to @group, notice: 'Not requested.'
      return
    end

    if @group.member?(@user)
      redirect_to @group, notice: 'You already are a member of this group.'
    elsif @group.requesting_user?(@user)
      redirect_to @group, notice: 'You already requested to join this group.'
    else
      @group.requesting_users << @user
      redirect_to @group, notice: 'Requested.'
    end
  end

  def delete_request
    if @group.requesting_user?(@user)
      @group.requesting_users.delete @user
      redirect_to @group, notice: 'Deleted request.'
    else
      redirect_to @group, notice: 'Not deleted request.'
    end
  end

  private
  def member_only
    only_group_member(@group)
  end

  def find_group
    @group = Group.find(params[:group_id])
  end

  def group_member_only
    only_group_member(@group) if @group.secret?
  end

  def user_group_params
    { role: params[:user_group].try(:[], :role) }
  end

  def find_user_group
    @user_group = UserGroup.find(params[:id])
  end

  def manager_only
    only_group_manager(@group)
  end

  def owner_only
    raise Group::NotGroupOwner if @group.owner?(@user_group.user)
  end
end
